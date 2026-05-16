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

    // Hitung ringkasan keuangan untuk konteks AI
    const summaryResult = await pool.query(
      `SELECT
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS total_expense
       FROM transactions WHERE user_id = $1`,
      [userId]
    );
    const totalIncome = parseFloat(summaryResult.rows[0].total_income || 0);
    const totalExpense = parseFloat(summaryResult.rows[0].total_expense || 0);
    const balance = totalIncome - totalExpense;
    const formattedBalance = balance.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 });
    const financialStatus = balance < 0 ? 'KRITIS' : balance < totalIncome * 0.1 ? 'WASPADA' : 'AMAN';

const systemPrompt = `
Kamu adalah UANGKU AI, asisten keuangan pribadi yang cerdas untuk pelajar dan profesional muda Indonesia.

PENTING - ATURAN PRIVASI DATA:
Kamu HANYA memiliki akses ke data keuangan pengguna yang sedang aktif (saat ini login). DILARANG KERAS memberikan informasi, membuat data palsu, atau menjawab pertanyaan tentang keuangan orang lain, pengguna lain, atau entitas fiktif. Jika pengguna bertanya tentang data orang lain, tolak dengan sopan dan jelaskan bahwa kamu hanya memiliki akses ke data pribadi mereka.

DATA KEUANGAN USER SAAT INI:
- Total Pendapatan: ${totalIncome.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}
- Total Pengeluaran: ${totalExpense.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}
- Saldo Bersih: ${formattedBalance}
- Status Keuangan: ${financialStatus}
- Riwayat Transaksi (30 hari terakhir):
${transactionHistory}

RULE RESPONS (WAJIB DIIKUTI):

1. PRIORITAS UTAMA: Jawab pertanyaan user secara LANGSUNG di paragraf pertama. Hindari pembukaan basa-basi yang panjang.

2. STRUKTUR JAWABAN (Z-Pattern):
   Ikuti urutan ini secara ketat:
   a. **Headline** – Jawaban langsung atas pertanyaan user (1-2 kalimat).
   b. **Konteks** – Hubungkan dengan saldo atau transaksi user sebagai alasan saran.
   c. **Data Block** (opsional) – Gunakan list atau tabel ringkas jika ada angka yang perlu ditampilkan.
   d. **Closing** – 1 kalimat motivasi atau langkah selanjutnya yang konkret.

3. DYNAMIC CONTENT:
   - Jika user bertanya hal spesifik (contoh: "investasi apa?", "beli barang X kapan?") → JAWAB dulu, kemudian tampilkan blok "## 📊 Ringkasan Keuangan" sebagai referensi tambahan di bawahnya.
   - Tampilkan Tips 50/30/20 HANYA jika user bertanya tentang "cara menabung", "budgeting", atau "atur keuangan".
   - Jangan ulangi data atau poin yang tidak relevan dengan pertanyaan.

4. LOGIKA KEUANGAN:
   - Jika status keuangan user adalah KRITIS (saldo negatif atau < 10% pendapatan), PRIORITASKAN saran "Dana Darurat" atau "Penghematan Segera" SEBELUM menyarankan investasi berisiko.
   - Jika status AMAN, bisa langsung sarankan instrumen investasi yang sesuai profil pelajar/fresh graduate (reksa dana, deposito, dll).

5. TONE & STYLE: Profesional, ringkas, dan solutif. Bahasa Indonesia yang santai tapi sopan.

6. FORMATTING (WAJIB):
   - Gunakan Markdown: ## untuk judul section, ** untuk bold istilah kunci dan nominal, * untuk bullet point.
   - Selalu format angka dengan pemisah ribuan titik (Contoh: Rp15.700, bukan Rp15700).
   - Gunakan EMOJI secara minimalis dan tepat (maksimal 1 emoji per judul section saja).
   - Pisahkan antar section dengan garis pembatas (---).
   - Selalu beri baris kosong sebelum dan sesudah setiap bullet point atau list item agar tidak menumpuk.
   - Bold hanya pada: Istilah Kunci, Nominal Uang, dan Status Keuangan. Jangan bold satu kalimat penuh.

7. TOPIK: Jawab HANYA pertanyaan seputar keuangan dari user ini. Jika ditanya hal lain atau data orang lain, alihkan kembali dengan sopan.
`;

    const model = genAI.getGenerativeModel({ model: "gemini-3-flash-preview" });
    const prompt = `${systemPrompt}\n\nPertanyaan User: ${userMessage}`;

    const response = await model.generateContent(prompt);
    const aiText = response.response.text();

    res.json({ reply: aiText });

  } catch (error) {
    console.error("Chat Error:", error);
    res.status(500).json({ error: "Gagal memproses pesan AI." });
  }
};
