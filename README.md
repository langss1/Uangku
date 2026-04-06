# 💰 UANGKU - Smart Financial Tracker
[cite_start]**Mobile Application Pencatatan Keuangan Inklusif Berbasis Artificial Intelligence** [cite: 2]

[cite_start]UANGKU adalah aplikasi berbasis Android yang dirancang untuk membantu pengguna melakukan pencatatan dan pemantauan keuangan pribadi secara praktis, terorganisir, dan inklusif[cite: 18, 26]. [cite_start]Aplikasi ini menggabungkan pencatatan manual dengan otomatisasi berbasis kecerdasan buatan (AI)[cite: 19].

## 🌟 Fitur Utama
* [cite_start]**Pencatatan Otomatis (OCR):** Pemindaian struk transaksi menggunakan teknologi *Computer Vision* (ML Kit) untuk mengekstraksi nominal, tanggal, dan nama merchant secara otomatis[cite: 20, 39, 119].
* [cite_start]**Chatbot Finansial (Gemini AI):** Asisten virtual interaktif yang memberikan analisis pola keuangan personal dan ringkasan kondisi finansial berdasarkan riwayat transaksi[cite: 21, 43, 183].
* [cite_start]**Visualisasi Statistik:** Grafik *Line Chart* dan *Pie Chart* interaktif untuk memantau tren serta kategori pengeluaran mingguan/bulanan[cite: 22, 51, 190].
* [cite_start]**Manajemen Anggaran (Budgeting):** Penetapan batas pengeluaran maksimal dengan sistem peringatan dini melalui *Push Notification*[cite: 53, 54, 56].
* [cite_start]**Multi-Currency:** Dukungan pencatatan dalam berbagai mata uang dengan konversi otomatis ke IDR menggunakan *Exchange Rate API*[cite: 58, 59, 60].
* [cite_start]**Manajemen Kalender:** Pemantauan riwayat pemasukan dan pengeluaran secara kronologis melalui tampilan kalender interaktif[cite: 22, 174].
* [cite_start]**Ekspor Laporan:** Dokumentasi laporan keuangan formal dalam format PDF atau CSV yang disimpan di penyimpanan internal perangkat[cite: 64, 66, 204].

## 🛠️ Tech Stack
* [cite_start]**Frontend:** Flutter & Dart (UI/UX Responsif)[cite: 71].
* [cite_start]**Native Integration:** Kotlin (Akses kontrol kamera tingkat rendah/low-level)[cite: 72, 73].
* [cite_start]**AI & Machine Learning:** * Gemini API (Analisis data kognitif & Chatbot)[cite: 84, 104].
    * [cite_start]Google ML Kit (On-device OCR untuk struk)[cite: 119, 120].
* **Backend & Database:**
    * [cite_start]PostgreSQL/MySQL (Penyimpanan pusat data profil dan riwayat)[cite: 79].
    * [cite_start]SQLite (Penyimpanan lokal untuk fitur *offline-first*)[cite: 80].
* **Security:**
    * [cite_start]SSL/Certificate Pinning (Mencegah serangan MitM)[cite: 86].
    * [cite_start]Enkripsi AES-256 (Untuk data lokal SQLite)[cite: 90].
    * [cite_start]Secure Storage & Code Obfuscation (ProGuard/R8)[cite: 91, 92].
    * [cite_start]Two-Factor Authentication (2FA) via Authenticator App[cite: 149].

## 👥 Tim Pengembang (TI Universitas Telkom)
| Nama | NIM | Fokus Fitur (PIC) |
| :--- | :--- | :--- |
| **Farhan Muamar Fawwaz** | 103032300076 | [cite_start]AI OCR Struk, Home Page, Konversi Mata Uang [cite: 5, 9, 212] |
| **Arina Rahmania Nabila** | 103032300129 | [cite_start]Manajemen Transaksi Manual, Kalender Riwayat [cite: 6, 10, 212] |
| **Gilang Wasis Wicaksono** | 103032300130 | [cite_start]Manajemen Akun (2FA), Security, Notifikasi Real-time [cite: 7, 11, 213] |
| **Ihab Hasanain Akmal** | 103032330054 | [cite_start]Chatbot AI Gemini, Statistik Grafik, Ekspor Laporan [cite: 8, 12, 212] |

## 🚀 Setup Pengembangan
Untuk menjalankan proyek ini di lingkungan lokal (Ubuntu/Linux):

1. **Persiapan Database:**
   [cite_start]Pastikan PostgreSQL berjalan (disarankan menggunakan Docker)[cite: 79].
   
2. **Koneksi Perangkat:**
   Jika menggunakan HP fisik untuk debugging, jalankan perintah ADB reverse:
   ```bash
   adb reverse tcp:8000 tcp:8000