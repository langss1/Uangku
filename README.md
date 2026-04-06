# 💰 UANGKU - Smart Financial Tracker
**Mobile Application Pencatatan Keuangan Inklusif Berbasis Artificial Intelligence**

UANGKU adalah aplikasi berbasis Android yang dirancang untuk membantu pengguna melakukan pencatatan dan pemantauan keuangan pribadi secara praktis, terorganisir, dan inklusif. Aplikasi ini menggabungkan pencatatan manual dengan otomatisasi berbasis kecerdasan buatan (AI).

## 🌟 Fitur Utama
* **Pencatatan Otomatis (OCR):** Pemindaian struk transaksi menggunakan teknologi Computer Vision (ML Kit) untuk mengekstraksi nominal, tanggal, dan nama merchant secara otomatis.
* **Chatbot Finansial (Gemini AI):** Asisten virtual interaktif yang memberikan analisis pola keuangan personal dan ringkasan kondisi finansial.
* **Visualisasi Statistik:** Grafik Line Chart dan Pie Chart interaktif untuk memantau tren serta kategori pengeluaran.
* **Manajemen Anggaran (Budgeting):** Penetapan batas pengeluaran maksimal dengan sistem peringatan dini melalui Push Notification.
* **Multi-Currency:** Dukungan pencatatan dalam berbagai mata uang dengan konversi otomatis ke IDR.
* **Manajemen Kalender:** Pemantauan riwayat pemasukan dan pengeluaran secara kronologis melalui tampilan kalender.
* **Ekspor Laporan:** Dokumentasi laporan keuangan formal dalam format PDF atau CSV.

## 🛠️ Tech Stack
* **Frontend:** Flutter & Dart.
* **Native Integration:** Kotlin.
* **AI & Machine Learning:** Gemini API & Google ML Kit (On-device OCR).
* **Backend & Database:** PostgreSQL/MySQL & SQLite.
* **Security:** SSL/Certificate Pinning, Enkripsi AES-256, Secure Storage, Code Obfuscation, & Two-Factor Authentication (2FA).

## 👥 Tim Pengembang (TI Universitas Telkom)
| Nama | NIM | Fokus Fitur (PIC) |
| :--- | :--- | :--- |
| **Farhan Muamar Fawwaz** | 103032300076 | AI OCR Struk, Home Page, Konversi Mata Uang |
| **Arina Rahmania Nabila** | 103032300129 | Manajemen Transaksi Manual, Kalender Riwayat |
| **Gilang Wasis Wicaksono** | 103032300130 | Manajemen Akun (2FA), Security, Notifikasi Real-time |
| **Ihab Hasanain Akmal** | 103032330054 | Chatbot AI Gemini, Statistik Grafik, Ekspor Laporan |

## 🚀 Setup Pengembangan
Untuk menjalankan proyek ini di lingkungan lokal (Ubuntu/Linux):

1. **Persiapan Database:**
   Pastikan PostgreSQL berjalan (disarankan menggunakan Docker).
   
2. **Koneksi Perangkat:**
   Jika menggunakan HP fisik untuk debugging, jalankan perintah ADB reverse di terminal:
   ```bash
   adb reverse tcp:8000 tcp:8000