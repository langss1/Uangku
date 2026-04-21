const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL Connection
// DATABASE_URL format: postgresql://username:password@host:port/database_name
const connectionString = process.env.DATABASE_URL || 'postgresql://ihab:apayhh@db:5432/finance_uangku';

const pool = new Pool({
  connectionString: connectionString,
});

pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Initialize database table if not exists
const initDb = async () => {
  const createTableQuery = `
    CREATE TABLE IF NOT EXISTS transactions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      category TEXT,
      is_synced INTEGER DEFAULT 1
    );
  `;
  try {
    await pool.query(createTableQuery);
    console.log('Database initialized: transactions table is ready.');
  } catch (err) {
    console.error('Error initializing database', err);
  }
};

initDb();

// Test endpoint
app.get('/', (req, res) => {
  res.send('UANGKU API is running.');
});

// Sync endpoint
// Receives an array of transactions to insert/update in PostgreSQL
app.post('/api/sync', async (req, res) => {
  const transactions = req.body.transactions;

  if (!transactions || !Array.isArray(transactions)) {
    return res.status(400).json({ error: 'Invalid payload. Expected an array of transactions.' });
  }

  if (transactions.length === 0) {
    return res.status(200).json({ message: 'No transactions to sync.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // UPSERT logic: Insert if not exists, update if exists (based on id)
    for (const trx of transactions) {
      const insertQuery = `
        INSERT INTO transactions (id, title, amount, date, type, category, is_synced)
        VALUES ($1, $2, $3, $4, $5, $6, 1)
        ON CONFLICT (id) DO UPDATE SET
          title = EXCLUDED.title,
          amount = EXCLUDED.amount,
          date = EXCLUDED.date,
          type = EXCLUDED.type,
          category = EXCLUDED.category,
          is_synced = 1;
      `;
      const values = [
        trx.id,
        trx.title,
        trx.amount,
        trx.date,
        trx.type,
        trx.category || null,
      ];
      await client.query(insertQuery, values);
    }

    await client.query('COMMIT');
    res.status(200).json({ message: 'Sync successful', syncedCount: transactions.length });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Sync error:', err);
    res.status(500).json({ error: 'Failed to sync transactions.' });
  } finally {
    client.release();
  }
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
