# 📝 Progress Log - Gilang (UANGKU App)

## 📅 Log: 2026-05-13
### 🚀 Perubahan Utama:
1.  **Refaktor Splash Screen:**
    *   Menghapus garis biru kecil di bawah logo agar UI lebih bersih.
    *   Menambahkan animasi bola-bola polar abstrak di latar belakang (background) yang bergerak secara acak.
    *   Memindahkan posisi animasi agar tidak menutupi logo (berada di layer belakang).
2.  **Perbaikan Home Page (Fix Blank Screen):**
    *   Menambahkan penanganan error (try-catch) pada proses inisialisasi user dan data.
    *   Mengubah proses pengambilan data backend dan notifikasi menjadi non-blocking (tanpa await di main thread) agar aplikasi tetap responsif.
3.  **Integrasi SQLite & Offline Capability:**
    *   Implementasi sistem simpan lokal menggunakan SQLite untuk setiap transaksi baru.
    *   Data sekarang disimpan ke memori (ValueNotifier) agar fetching tidak memberatkan, dan otomatis termuat saat offline.
    *   Menambahkan logika sinkronisasi otomatis saat aplikasi dibuka: Jika ada data yang belum ter-sync (saat offline sebelumnya), sistem akan otomatis mengunggahnya ke backend saat koneksi tersedia di Splash Screen.
4.  **Fitur Hitung & Budgeting:**
    *   Memastikan fitur perhitungan (penambahan/pengurangan saldo) sudah berjalan dengan benar saat online maupun offline.

---
*Log ini akan terus diperbarui seiring berjalannya progres.*
