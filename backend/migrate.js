const pool = require('./config/db');

const migrate = async () => {
  try {
    console.log('🔄 Starting database migration...');
    const client = await pool.connect();
    
    // Create users table
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        full_name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        totp_secret VARCHAR(255),
        is_2fa_active BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Transactions table linked to users
    const createTransactionsTable = `
      DROP TABLE IF EXISTS transactions;
      CREATE TABLE transactions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        is_synced INTEGER DEFAULT 1
      );
    `;

    // Notifications table
    const createNotificationsTable = `
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) DEFAULT 'info',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `;

    await client.query('BEGIN');
    
    console.log('📦 Creating/Verifying users table...');
    await client.query(createUsersTable);
    
    console.log('📦 Creating/Verifying transactions table...');
    await client.query(createTransactionsTable);

    console.log('📦 Creating/Verifying notifications table...');
    await client.query(createNotificationsTable);
    
    await client.query('COMMIT');
    console.log('✅ Database migration completed successfully!');
    
    client.release();
  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    pool.end();
  }
};

migrate();
