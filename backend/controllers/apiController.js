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

const getMockAIResponse = (userMessage, userName, totalIncome, totalExpense, balance, formattedBalance, financialStatus, transactionHistory) => {
  const msg = userMessage.toLowerCase().trim();

  if (msg.includes('halo') || msg.includes('hi ') || msg.includes('hai') || msg.includes('helo')) {
    return `Halo **${userName}**! Saya **UANGKU AI**, asisten keuangan pribadi cerdas Anda. 👋

Berdasarkan pencatatan saya, saldo bersih Anda saat ini adalah **${formattedBalance}** dengan status keuangan **${financialStatus}**. 

Ada yang bisa saya bantu untuk mengoptimalkan anggaran atau menganalisis transaksi Anda hari ini? 📈`;
  }

  if (msg.includes('tips') || msg.includes('budgeting') || msg.includes('tabung') || msg.includes('simpan') || msg.includes('hemat')) {
    const kebutuhan = (totalIncome > 0 ? totalIncome * 0.5 : 1500000);
    const keinginan = (totalIncome > 0 ? totalIncome * 0.3 : 900000);
    const tabungan = (totalIncome > 0 ? totalIncome * 0.2 : 600000);

    return `Tentu, **${userName}**! Untuk mengelola keuangan secara sehat, saya sangat menyarankan metode alokasi **50/30/20** yang disesuaikan dengan profil Anda:

## 📊 Rekomendasi Alokasi Anggaran Anda
* **50% Kebutuhan Pokok**: Sisihkan sekitar **${kebutuhan.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}** untuk kebutuhan wajib bulanan (kos, makan, transportasi).
* **30% Keinginan Pribadi**: Batasi maksimal **${keinginan.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}** untuk hobi, nongkrong, atau belanja tersier.
* **20% Masa Depan**: Investasikan minimal **${tabungan.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}** langsung ke tabungan dana darurat atau reksa dana.

---
💡 *Tips Tambahan*: Karena status keuangan Anda saat ini adalah **${financialStatus}**, cobalah untuk fokus membangun dana darurat minimal 3x pengeluaran bulanan terlebih dahulu!`;
  }

  if (msg.includes('analisis') || msg.includes('pengeluaran') || msg.includes('transaksi') || msg.includes('belanja')) {
    return `Berikut adalah analisis mendalam mengenai pengeluaran milik **${userName}** selama 30 hari terakhir:

## 📊 Ringkasan Neraca Keuangan
* Total Pendapatan: **${totalIncome.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}**
* Total Pengeluaran: **${totalExpense.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}**
* Saldo Saat Ini: **${formattedBalance}** (${financialStatus})

## 🔍 Wawasan Transaksi Terakhir
${transactionHistory.split('\n').slice(0, 3).join('\n')}

---
${financialStatus === 'KRITIS' 
  ? '⚠️ **Saran Penting**: Pengeluaran Anda melebihi pendapatan! Segera batasi transaksi non-prioritas hari ini juga untuk menghindari defisit berkepanjangan.' 
  : '👍 **Saran Penting**: Pengeluaran Anda berada dalam batas aman. Pertahankan disiplin mencatat keuangan Anda!'} 🚀`;
  }

  if (msg.includes('investasi') || msg.includes('saham') || msg.includes('reksadana')) {
    return `Halo **${userName}**, berinvestasi adalah langkah cerdas untuk melawan inflasi. Berikut adalah saran instrumen investasi yang cocok untuk profil saldo **${formattedBalance}** Anda:

## 📈 Pilihan Investasi Pelajar & Muda
* **Reksa Dana Pasar Uang (RDPU)**: Sangat direkomendasikan karena risiko hampir nol, bisa dicairkan kapan saja, dan mulai dari Rp10.000 saja.
* **Emas Digital**: Sangat stabil sebagai pelindung nilai (safe haven) jangka panjang.

---
${financialStatus === 'KRITIS' 
  ? '⚠️ **Catatan**: Mengingat status finansial Anda masih **KRITIS**, tunda investasi berisiko tinggi. Amankan dana darurat di tabungan biasa terlebih dahulu.' 
  : 'Ayo mulai alokasikan 10% - 20% dari pendapatan Anda secara konsisten setiap bulan!'}`;
  }

  // Default response
  return `Halo **${userName}**! Saya memahami pesan Anda mengenai pencarian informasi keuangan. 

Sebagai asisten keuangan **UANGKU AI**, berikut adalah evaluasi kondisi akun Anda saat ini:

## 📊 Status Finansial Terkini
* Saldo Anda saat ini: **${formattedBalance}** dengan status **${financialStatus}**.
* Total Pengeluaran Bulanan: **${totalExpense.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })}**

---
Silakan gunakan tombol rekomendasi di bawah chat untuk tips instan tentang **budgeting**, **analisis pengeluaran**, atau tanya langsung hal spesifik lainnya kepada saya! 💡`;
};

exports.postChat = async (req, res) => {
  const userId = req.user.id;
  const { userMessage } = req.body;

  try {
    // Get user's full name and AI preference to enforce strict privacy
    const userResult = await pool.query('SELECT full_name, pref_ai_insights FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) return res.status(404).json({ error: "User not found" });
    
    const user = userResult.rows[0];
    const userName = user.full_name || 'Pengguna';
    
    if (user.pref_ai_insights === false) {
      return res.status(403).json({ error: "Fitur Wawasan AI sedang dimatikan di pengaturan profil Anda. Silakan aktifkan untuk mulai chat." });
    }

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

    // fallback check if Gemini API key is missing
    if (!genAI) {
      console.warn("⚠️ Gemini API Key is missing. Using intelligent local fallback response.");
      const reply = getMockAIResponse(userMessage, userName, totalIncome, totalExpense, balance, formattedBalance, financialStatus, transactionHistory);
      return res.json({ reply });
    }

    const systemPrompt = `
Kamu adalah UANGKU AI, asisten keuangan pribadi yang cerdas untuk pelajar dan profesional muda Indonesia.

PENTING - ATURAN PRIVASI DATA:
Nama pengguna yang sedang login saat ini adalah: "${userName}".
Kamu HANYA memiliki akses ke data keuangan milik "${userName}".
DILARANG KERAS memberikan informasi, membuat data palsu, atau menjawab pertanyaan tentang keuangan orang lain selain "${userName}".
JIKA pengguna meminta untuk melihat data orang lain (menyebut nama yang BUKAN "${userName}"), KAMU WAJIB MENOLAK DENGAN TEGAS. Katakan bahwa kamu hanya asisten pribadi untuk "${userName}" dan tidak memiliki akses ke data orang lain.

DATA KEUANGAN MILIK ${userName.toUpperCase()}:
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
   - Jika status AMAN, bisa langsung sarankan instrumen investasi yang sesuai profil profil pelajar/fresh graduate (reksa dana, deposito, dll).

5. TONE & STYLE: Profesional, ringkas, dan solutif. Bahasa Indonesia yang santai tapi sopan.

6. FORMATTING (WAJIB):
   - Gunakan Markdown: ## untuk judul section, ** untuk bold istilah kunci dan nominal, * untuk bullet point.
   - Selalu format angka dengan pemisah ribuan titik (Contoh: Rp15.700, bukan Rp15700).
   - Gunakan EMOJI secara minimalis dan tepat (maksimal 1 emoji per judul section saja).
   - Pisahkan antar section dengan garis pembatas (---).
   - Selalu beri baris kosong sebelum dan sesudah setiap bullet point atau list item agar tidak menumpuk.
   - Bold hanya pada: Istilah Kunci, Nominal Uang, dan Status Keuangan. Jangan bold satu kalimat penuh.

7. TOPIK: Jawab HANYA pertanyaan seputar keuangan milik "${userName}". Jika ditanya hal lain atau data orang lain, tolak dengan sopan.
`;

    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    const prompt = `${systemPrompt}\n\nPertanyaan User: ${userMessage}`;

    const response = await model.generateContent(prompt);
    let aiText = response.response.text();
    
    // Clean up empty bullet points generated by AI
    aiText = aiText.replace(/^\s*\*\s*$/gm, '');

    res.json({ reply: aiText.trim() });

  } catch (error) {
    console.error("Chat Error:", error);
    const errMsg = error.message || "";
    
    // Check if error is due to invalid API key or network and fallback seamlessly
    if (errMsg.includes("API key not valid") || errMsg.includes("API_KEY_INVALID") || errMsg.includes("403") || errMsg.includes("Forbidden") || errMsg.includes("fetch failed") || errMsg.includes("ENOTFOUND")) {
      console.warn("⚠️ Gemini API Call failed due to key/network issue. Using intelligent local fallback response.");
      try {
        // Re-calculate user variables for the fallback response
        const userResult = await pool.query('SELECT full_name FROM users WHERE id = $1', [userId]);
        const userName = userResult.rows[0]?.full_name || 'Pengguna';
        const result = await pool.query('SELECT title, amount, category, date FROM transactions WHERE user_id = $1 ORDER BY date DESC LIMIT 10', [userId]);
        const transactions = result.rows;
        const transactionHistory = transactions.length > 0
          ? transactions.map(t => `- ${t.date}: ${t.title} (Rp${t.amount}) [${t.category}]`).join('\n')
          : "Belum ada riwayat transaksi.";
        const summaryResult = await pool.query(`SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS total_income, SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS total_expense FROM transactions WHERE user_id = $1`, [userId]);
        const totalIncome = parseFloat(summaryResult.rows[0].total_income || 0);
        const totalExpense = parseFloat(summaryResult.rows[0].total_expense || 0);
        const balance = totalIncome - totalExpense;
        const formattedBalance = balance.toLocaleString('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 });
        const financialStatus = balance < 0 ? 'KRITIS' : balance < totalIncome * 0.1 ? 'WASPADA' : 'AMAN';

        const reply = getMockAIResponse(userMessage, userName, totalIncome, totalExpense, balance, formattedBalance, financialStatus, transactionHistory);
        return res.json({ reply });
      } catch (innerError) {
        console.error("Critical Fallback Error:", innerError);
      }
    }
    res.status(500).json({ error: "Gagal memproses pesan AI: " + errMsg });
  }
};
