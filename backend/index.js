const express = require('express');
const cors = require('cors');
const pool = require('./config/db');

// Import routes
const authRoutes = require('./routes/authRoutes');
const apiRoutes = require('./routes/apiRoutes');

const app = express();
const port = process.env.PORT || 8000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes Mount
app.use('/api/auth', authRoutes);
app.use('/api/data', apiRoutes);

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
