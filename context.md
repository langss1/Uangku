# 💰 Project Context: UANGKU - Smart Financial Tracker

Dokumen ini berisi detail teknis, arsitektur, dan logika proyek **UANGKU** untuk memberikan konteks bagi AI atau pengembang lain.

## 🌟 Ringkasan Proyek
UANGKU adalah aplikasi manajemen keuangan pribadi yang menggabungkan pencatatan manual, otomatisasi berbasis AI (OCR), dan asisten cerdas (Gemini AI). Proyek ini terdiri dari aplikasi mobile (Flutter) dan backend API (Node.js/Express).

---

## 🛠️ Tech Stack

### 1. Frontend (Mobile App)
*   **Framework:** Flutter (Dart)
*   **AI Integration:** 
    *   `google_generative_ai`: Chatbot Gemini untuk analisis keuangan.
    *   `google_mlkit_text_recognition`: OCR untuk pemindaian struk.
*   **Data Visualization:** `fl_chart` untuk grafik statistik.
*   **Local Storage:** `sqflite` (Database SQL lokal) & `shared_preferences`.
*   **Security:** `flutter_local_notifications`, 2FA UI integration.
*   **Assets:** Animasi login video (.mp4), logo splash screen.

### 2. Backend (REST API)
*   **Runtime:** Node.js (Express.js)
*   **Database:** PostgreSQL (Relational Database)
*   **Authentication:** 
    *   `jsonwebtoken` (JWT) untuk manajemen session.
    *   `bcrypt` untuk hashing password.
*   **Security (2FA):** 
    *   `speakeasy`: Implementasi TOTP (Time-based One-Time Password).
    *   `qrcode`: Pembuatan QR Code untuk registrasi authenticator app.
*   **Deployment:** Dockerized (terdapat `Dockerfile` dan `docker-compose.yml`).

---

## 📁 Struktur Folder Utama

### Backend (`/backend`)
*   `index.js`: Entry point server.
*   `migrate.js`: Skrip migrasi skema database PostgreSQL.
*   `config/`: Konfigurasi database.
*   `controllers/`: Logika bisnis (Auth, Transaksi, Budget, AI Chat).
*   `routes/`: Definisi endpoint (Auth & API).
*   `middleware/`: Proteksi rute menggunakan JWT.

### Mobile App (`/uangku_app`)
*   `lib/core/`: Komponen inti seperti `database_helper.dart` (SQFlite) dan API client.
*   `lib/features/`: Implementasi fitur per modul (Clean Architecture-ish):
    *   `auth/`: Login, Register, 2FA Verification.
    *   `home/`: Dashboard ringkasan saldo.
    *   `transaction/`: Riwayat dan input pengeluaran/pemasukan.
    *   `scan/`: Logika OCR ML Kit.
    *   `chat/`: Antarmuka Chatbot Gemini.
    *   `analytics/`: Statistik visual.
    *   `budget/`: Manajemen limit anggaran.

---

## 🧠 Logika & Alur Penting

### 1. Autentikasi & 2FA
Sistem menggunakan dua lapis keamanan:
*   **Login Tahap 1:** Email & Password. Jika benar, server mengecek status `is_2fa_active`.
*   **Login Tahap 2:** Jika 2FA aktif, server mengirim respons `requires2FA`. Flutter akan menampilkan screen input 6-digit kode TOTP yang diverifikasi via endpoint `/auth/login-2fa`.

### 2. Sinkronisasi Data (Local & Remote)
*   Aplikasi menggunakan `database_helper.dart` untuk menyimpan transaksi secara lokal menggunakan SQFlite.
*   Terdapat flag `is_synced` pada tabel transaksi untuk menandai data yang belum terunggah ke server PostgreSQL saat offline.

### 3. Ekstraksi Data OCR
*   Modul `scan` menggunakan kamera untuk mengambil gambar struk.
*   ML Kit mengekstrak teks, lalu logika Regex/Parsing digunakan untuk mencari nominal harga total, tanggal, dan nama merchant secara otomatis sebelum disimpan.

### 4. Chatbot AI Gemini
*   User dapat bertanya tentang kondisi keuangan.
*   Backend atau Frontend mengirimkan prompt ke Gemini API yang bisa disertai dengan ringkasan data transaksi user (secara anonim/agregat) untuk memberikan jawaban yang relevan.

---

## 📊 Skema Database (PostgreSQL)
*   **`users`**: `id, full_name, email, password_hash, totp_secret, is_2fa_active`.
*   **`transactions`**: `id, user_id, title, amount, date, type (income/expense), category, is_synced`.
*   **`budgets`**: `id, user_id, category, amount, start_date, end_date`.
*   **`notifications`**: `id, user_id, title, message, is_read`.

---

> [!NOTE]
> Proyek ini sedang dalam tahap pengembangan intensif untuk fitur **Analytics** dan **Budgeting**. Pastikan untuk selalu menjalankan `migrate.js` jika ada perubahan pada struktur database backend.
