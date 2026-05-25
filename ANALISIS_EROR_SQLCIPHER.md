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

---

## 🎓 Strategi Pertahanan Proposal: Solusi & Alternatif Pengamanan Storage yang Lebih Baik

Jika **"Data Encryption at Rest (Enkripsi Data Lokal)"** sudah terlanjur tertulis di dalam proposal Anda, Anda **tidak perlu panik atau mengganti isi proposal secara radikal**. 

Sebaliknya, Anda dapat tampil sebagai **software engineer yang kritis dan solutif** dengan menjelaskan bahwa Anda telah melakukan *Research & Development* (R&D) secara mendalam, mengidentifikasi kelemahan fatal dari *Full-Disk Database Encryption* (SQLCipher) lewat eksperimen berulang, dan **menawarkan opsi mitigasi alternatif yang jauh lebih cerdas dan stabil** sebagai berikut:

### Opsi Alternatif 1: Granular Field-Level Encryption (Enkripsi Tingkat Kolom/Field) - [SANGAT DIREKOMENDASIKAN]
* **Konsep**: Daripada mengenkripsi **seluruh file database** (SQLCipher) yang rawan membuat file korup dan ter-wipe saat kunci hilang, kita hanya mengenkripsi **kolom-kolom data yang benar-benar sensitif** (seperti nominal uang `amount` atau nama transaksi `title`) menggunakan pustaka kriptografi Dart biasa (seperti algoritma **AES-256** dari package `encrypt` di Flutter) sebelum data dimasukkan ke SQLite biasa.
* **Keunggulan Pertahanan**:
  - **100% Menepati Janji Proposal**: Data sensitif pengguna tetap tersimpan dalam keadaan terenkripsi di memori HP (*Encryption at Rest*). Jika file database diekstraksi secara ilegal dari luar Sandbox, peretas hanya akan melihat string acak tak terbaca.
  - **Anti-Data Loss**: Jika kunci enkripsi di KeyStore terhapus secara asinkron oleh OS Android, **berkas database SQLite tidak akan rusak/corrupt!** Aplikasi tetap bisa terbuka dengan mulus, dan data transaksi non-sensitif tetap ada. Hanya data terenkripsi yang sementara tidak bisa dibaca sebelum pengguna login ulang untuk memulihkan kunci dekripsi baru dari server backend.

### Opsi Alternatif 2: Cloud-Backed Key Backup & Recovery System
* **Konsep**: Masalah utama SQLCipher adalah hilangnya kunci lokal dari KeyStore secara mendadak. Kita tetap menggunakan enkripsi database, namun kunci enkripsi database (db password) tersebut **dicadangkan secara aman di server backend (Cloud)**.
* **Keunggulan Pertahanan**:
  - Jika Android KeyStore lokal mengalami *wipe* memori, aplikasi tidak akan langsung menghapus database. Aplikasi akan memanggil API backend secara aman (setelah pengguna memasukkan password akun mereka) untuk mengunduh kembali kunci dekripsi database tersebut dari server.

### Opsi Alternatif 3: Biometric Access Control & Secure Sandbox Gatekeeping
* **Konsep**: Mengalihkan fokus keamanan dari *file-level encryption* ke *access control* fisik (mengunci pintu masuk). Pengguna wajib melewati otentikasi Biometrik (Sidik Jari/FaceID) atau PIN lokal sebelum aplikasi diizinkan membaca file SQLite biasa yang diisolasi di dalam Sandbox privat Android.
* **Keunggulan Pertahanan**:
  - Menjelaskan bahwa proteksi fisik biometrik yang dipadukan dengan sandbox OS tingkat kernel adalah standar industri modern yang jauh lebih stabil untuk menjaga kerahasiaan data di perangkat pengguna tanpa mengorbankan stabilitas memori.
