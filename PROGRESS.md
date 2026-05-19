# Progress Update - Fitur 2FA & Menu Profil

Berikut adalah rincian pekerjaan dan perubahan yang telah kita lakukan pada aplikasi Uangku (Backend & Frontend):

## 1. Backend (Autentikasi & 2FA)
- **Implementasi 2FA Ganda**: Menambahkan fitur Two-Factor Authentication menggunakan Google Authenticator (via `otplib`) dan Email OTP (via `nodemailer`).
- **Skema Database**: Menyesuaikan logika autentikasi di `authController.js` agar menggunakan kolom `totp_secret` dan `is_2fa_active` sesuai dengan skema database lama Anda untuk fitur Google Authenticator.
- **Login Intercept**: Memodifikasi endpoint Login agar mengembalikan `tempToken` dan status `requires2FA` jika user memiliki 2FA aktif, sehingga user harus melewati layar verifikasi OTP sebelum mendapatkan token akses utama.

## 2. Sinkronisasi Git
- **Git Pull & Merge**: Berhasil melakukan sinkronisasi dengan repositori remote (`origin/main`) menggunakan strategi merge, sehingga kode lokal Anda sekarang sudah menyertakan update terbaru dari kolaborator lain tanpa menimpa kodingan 2FA yang baru dibuat.

## 3. Frontend (Aplikasi Flutter Uangku)
- **State Management**: Mengintegrasikan package `provider` untuk mengelola state global aplikasi (Tema, Bahasa, dan Mata Uang) menggunakan `PreferencesProvider`.
- **App Preferences**: 
  - **Dark Mode**: Mengimplementasikan fitur Mode Gelap (`darkTheme` ditambahkan di `app_theme.dart`). State disimpan secara permanen dengan `shared_preferences`.
  - **Language**: Menambahkan fitur pemilihan bahasa (Inggris dan Bahasa Indonesia).
  - **Currency**: Menambahkan fitur pemilihan format mata uang (IDR, USD, EUR, JPY).
- **Help & Support**: 
  - Mendesain ulang halaman Bantuan & Dukungan dengan daftar FAQ (Frequently Asked Questions).
  - Menambahkan tombol "Email Us" yang akan langsung membuka aplikasi Email pengguna (menggunakan package `url_launcher`) dan membuat draf pesan ke `uangku.apps@gmail.com`.
- **QR Code 2FA**: Mengintegrasikan package `qr_flutter` untuk merender barcode rahasia dari backend agar bisa di-scan oleh Google Authenticator.

## 4. Package Baru yang Ditambahkan
- Backend: `otplib`, `nodemailer`
- Frontend: `qr_flutter`, `url_launcher`, `provider`

---
*Catatan: Pastikan untuk menjalankan ulang (restart) aplikasi Flutter Anda agar package `url_launcher` dan `provider` dapat dimuat dengan baik oleh sistem.*
