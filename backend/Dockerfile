# Menggunakan base image Node.js versi 18 yang ringan (alpine)
FROM node:18-alpine

# Menentukan folder kerja di dalam container Docker
WORKDIR /app

# Menyalin file konfigurasi package.json (dan package-lock.json jika ada) lebih dulu
COPY package*.json ./

# Menginstal semua library yang dibutuhkan (seperti express, pg, cors)
RUN npm install

# Menyalin seluruh kode sisa (seperti index.js) dari laptop/VPS ke dalam container
COPY . .

# Membuka port 8000 agar bisa diakses dari luar (oleh Flutter)
EXPOSE 8000

# Perintah utama untuk menjalankan server saat container menyala
CMD ["node", "index.js"]