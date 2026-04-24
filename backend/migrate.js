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

    // Ensure transactions table exists and correctly matching our logic
    const createTransactionsTable = `
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

    await client.query('BEGIN');
    
    console.log('📦 Creating/Verifying users table...');
    await client.query(createUsersTable);
    
    console.log('📦 Creating/Verifying transactions table...');
    await client.query(createTransactionsTable);
    
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
