const pool = require('../config/db');

exports.getDashboard = async (req, res) => {
  const userId = req.user.id;
  try {
    const balanceResult = await pool.query(
      `SELECT 
        SUM(CASE WHEN type='income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN type='expense' THEN amount ELSE 0 END) as total_expense
       FROM transactions WHERE user_id = $1`,
      [userId]
    );

    const txResult = await pool.query(
      `SELECT * FROM transactions WHERE user_id = $1 ORDER BY date DESC LIMIT 10`,
      [userId]
    );

    const income = balanceResult.rows[0].total_income || 0;
    const expense = balanceResult.rows[0].total_expense || 0;
    const balance = income - expense;

    res.json({
      balance,
      income,
      expense,
      recent_transactions: txResult.rows
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to load dashboard data' });
  }
};

exports.getTransactions = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM transactions WHERE user_id = $1 ORDER BY date DESC', [req.user.id]);
    res.json(result.rows);
  } catch(error) {
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
};

exports.addTransaction = async (req, res) => {
  const { title, amount, date, type, category } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO transactions (user_id, title, amount, date, type, category) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [req.user.id, title, amount, date, type, category]
    );
    res.status(201).json(result.rows[0]);
  } catch(error) {
    res.status(500).json({ error: 'Failed to add transaction' });
  }
};

exports.getNotifications = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC', [req.user.id]);
    res.json(result.rows);
  } catch(error) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
};
