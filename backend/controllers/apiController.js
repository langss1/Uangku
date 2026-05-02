const { GoogleGenerativeAI } = require('@google/generative-ai');
const pool = require('../config/db');

const genAI = process.env.GEMINI_API_KEY ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY) : null;

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
  } catch (error) {
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
  } catch (error) {
    res.status(500).json({ error: 'Failed to add transaction' });
  }
};

exports.getNotifications = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC', [req.user.id]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
};

exports.getBudgets = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM budgets WHERE user_id = $1 ORDER BY created_at DESC', [req.user.id]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch budgets' });
  }
};

exports.addBudget = async (req, res) => {
  const { id, category, amount, startDate, endDate, iconCodePoint, bgColor, iconColor } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO budgets (id, user_id, category, amount, start_date, end_date, icon_code_point, bg_color, icon_color) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [id, req.user.id, category, amount, startDate, endDate, iconCodePoint, bgColor, iconColor]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Add budget error:', error);
    res.status(500).json({ error: 'Failed to add budget' });
  }
};

exports.updateBudget = async (req, res) => {
  const { id } = req.params;
  const { category, amount, startDate, endDate, iconCodePoint, bgColor, iconColor } = req.body;
  try {
    const result = await pool.query(
      `UPDATE budgets SET category = $1, amount = $2, start_date = $3, end_date = $4, icon_code_point = $5, bg_color = $6, icon_color = $7, updated_at = CURRENT_TIMESTAMP
       WHERE id = $8 AND user_id = $9 RETURNING *`,
      [category, amount, startDate, endDate, iconCodePoint, bgColor, iconColor, id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Budget not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update budget error:', error);
    res.status(500).json({ error: 'Failed to update budget' });
  }
};

exports.deleteBudget = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM budgets WHERE id = $1 AND user_id = $2 RETURNING *', [id, req.user.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Budget not found' });
    }
    res.json({ message: 'Budget deleted successfully' });
  } catch (error) {
    console.error('Delete budget error:', error);
    res.status(500).json({ error: 'Failed to delete budget' });
  }
};

exports.postChat = async (req, res) => {
  const userId = req.user.id;
  const { userMessage } = req.body;

  if (!genAI) {
    return res.status(500).json({ error: "Gemini API Key is missing in backend environment." });
  }

  try {
    const result = await pool.query(
      'SELECT title, amount, category, date FROM transactions WHERE user_id = $1 ORDER BY date DESC LIMIT 10',
      [userId]
    );

    const transactions = result.rows;

    const transactionHistory = transactions.length > 0
      ? transactions.map(t => `- ${t.date}: ${t.title} (Rp${t.amount}) [${t.category}]`).join('\n')
      : "Belum ada riwayat transaksi.";

    const systemPrompt = `
Persona: You are UANGKU AI, a professional and friendly expert personal finance advisor for Indonesian students and young professionals.
Role: Your task is to analyze user spending patterns, offer budgeting advice (like the 50/30/20 rule), and help users save money.
Context: Below is the user's recent transaction history. Use this as your primary data source for analysis.
Constraints:
- Respond in Indonesian (Bahasa Indonesia) unless asked otherwise.
- Be concise, friendly, and trustworthy.
- Base your analysis ONLY on the provided transaction data.
- If a user asks about something unrelated to finance, politely redirect them back.

User's Recent Transactions:
${transactionHistory}
`;

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const prompt = `${systemPrompt}\n\nPertanyaan User: ${userMessage}`;

    const response = await model.generateContent(prompt);
    const aiText = response.response.text();

    res.json({ reply: aiText });

  } catch (error) {
    console.error("Chat Error:", error);
    res.status(500).json({ error: "Gagal memproses pesan AI." });
  }
};
