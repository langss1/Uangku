# 📊 Brainstorming & Analisis Teknis: Mengapa Enkripsi SQLite (SQLCipher) Sering Mengalami Eror Data Hilang di Android?

Dokumen ini menyajikan hasil analisis mendalam (*brainstorming*) mengenai alasan mengapa kombinasi **SQLCipher (Enkripsi SQLite AES-256)** dan **Secure Storage** sering kali mengalami kegagalan (*crash* atau data terhapus total) pada aplikasi Flutter yang berjalan di sistem operasi Android.

---

## 🔍 Alur Kerja Enkripsi Database Lokal
Sebelum masuk ke analisis eror, berikut adalah alur kerja ideal yang dirancang sebelumnya:
1. **Pendaftaran/Login**: Aplikasi mengambil atau menghasilkan kunci acak (password) unik.
2. **Penyimpanan Kunci**: Kunci tersebut disimpan ke dalam **Android KeyStore** menggunakan `FlutterSecureStorage`.
3. **Pembukaan Database**: Saat aplikasi dibuka kembali, aplikasi mengambil kunci dari Secure Storage, lalu menggunakannya untuk membuka file database terenkripsi via **SQLCipher**.

---

## 💥 4 Akar Penyebab Kegagalan Enkripsi SQLite (SQLCipher)

### 1. Gangguan Kunci pada Android KeyStore (Master Key Wiping)
> [!IMPORTANT]
> **Android KeyStore** adalah sistem tingkat perangkat keras (Hardware-backed Keystore / TEE) yang bertugas mengamankan kunci enkripsi secara native di dalam chip fisik ponsel.

* **Masalah**: Pada beberapa vendor Android (khususnya Samsung dengan optimasi RAM agresif, Xiaomi MIUI/HyperOS, atau Oppo), sistem operasi sering kali melakukan "pembersihan memori paksa" (*aggressive process killing*) saat aplikasi berada di latar belakang atau ketika baterai lemah.
* **Dampak**: Proses pembersihan ini terkadang membuat Android KeyStore **membuang atau merusak Master Key** enkripsi secara sepihak untuk membebaskan ruang memori aman (Secure Element).
* **Akibat**: Saat aplikasi dibuka kembali, Secure Storage melempar `DecryptionException` atau mengembalikan nilai kosong (`null`). Kunci untuk membuka database pun **hilang selamanya**.

---

### 2. SQLCipher "Database File is Not a Database" (Invalid Key & Auto-Reset)
* **Masalah**: Ketika kunci dekripsi dari Secure Storage rusak atau mengembalikan `null` akibat masalah KeyStore di atas, aplikasi terpaksa mengoper nilai kosong (`""` atau `null`) ke fungsi `openDatabase()` milik SQLCipher.
* **Dampak**: SQLCipher mendeteksi bahwa kunci yang diberikan salah dan menolak membuka file database tersebut dengan pesan error:
  `[SQLITE_NOTADB] file is not a database or database disk image is malformed`.
* **Logika Penghapusan (Auto-Reset)**: Agar aplikasi tidak mengalami macet total (*persistent crash* / *force close* abadi) bagi pengguna, pustaka SQLite/boilerplates sering kali menyertakan mekanisme pengaman otomatis: **jika database gagal dibuka karena dianggap rusak, hapus berkas database lama dan buat database baru yang kosong**.
* **Hasil Akhir**: Aplikasi berhasil terbuka kembali, tetapi **seluruh data transaksi keuangan pengguna terhapus total (ter-wipe)** seolah-olah data hilang sendiri.

---

### 3. Masalah Sinkronisasi Asinkron (Race Condition) saat Startup
* **Masalah**: Proses membaca kunci dari Secure Storage di Flutter bersifat asinkron (`await storage.read()`), yang berjalan melalui *Platform Channel* native Android. Di sisi lain, siklus hidup aplikasi Flutter sangat cepat saat memuat halaman pertama (Splash/Home).
* **Dampak**: Terjadi *race condition* di mana `DatabaseHelper` mencoba menginisialisasi database sebelum platform native Android Secure Storage selesai merespons pembacaan kunci (memakan waktu beberapa ratus milidetik pada ponsel berspesifikasi rendah).
* **Akibat**: Database dibuka menggunakan kunci default atau kunci kosong, mengakibatkan SQLCipher menolak akses atau mengunci database secara permanen.

---

### 4. Kompatibilitas OS & Custom ROMs (EncryptedSharedPreferences Bug)
* **Masalah**: Pustaka Secure Storage menggunakan kelas `EncryptedSharedPreferences` bawaan Android Jetpack Security.
* **Dampak**: Kelas native Android ini terkenal memiliki bug internal yang sangat mengganggu di mana file XML tempat menyimpan kunci sering kali korup (*corrupted*) setelah perangkat mengalami restart (*reboot*) atau setelah sistem operasi menerima pembaruan (*OS updates*).
* **Hasil**: Meskipun kunci tersimpan dengan benar secara logis, OS Android tidak lagi bisa mendekripsi file preferensi tersebut untuk mengembalikan kunci database.

---

## 🛡️ Kesimpulan Rekomendasi Arsitektur yang Stabil
Demi memastikan **keandalan data tingkat tinggi (Data Integrity & Anti-Data Loss)** bagi pengguna akhir, arsitektur terbaik untuk aplikasi keuangan berskala menengah yang mendukung fitur sinkronisasi online adalah:

1. **Gunakan SQLite Standar (`sqflite`)**: Menghilangkan lapisan enkripsi file SQLCipher guna mencegah kegagalan baca akibat kehilangan kunci di perangkat keras.
2. **Gunakan SharedPreferences untuk Session**: Menyimpan data sesi non-sensitif (seperti alamat email aktif) di penyimpanan SharedPreferences standar yang dijamin tidak akan pernah hilang setelah restart.
3. **Gunakan Secure Storage HANYA untuk Token JWT**: Amankan token autentikasi API di Secure Storage dengan mengaktifkan fitur `resetOnError: true`. Jika token ini hilang akibat bug KeyStore, dampaknya **sangat minim** (pengguna hanya perlu melakukan login ulang, tetapi seluruh data transaksi lokalnya yang tersimpan di SQLite tetap aman dan tidak terhapus).
