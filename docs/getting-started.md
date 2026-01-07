# Panduan Memulai

Panduan singkat untuk menyalakan backend CodeIgniter 4 dan frontend Flutter (offline-first dengan SQLite), lalu menguji sinkronisasi REST API.

## Prasyarat
- PHP 8.1+ dengan composer
- MySQL/SQL Server (sesuaikan di `.env` backend)
- Flutter 3.10+ dan Dart 3, Android/iOS SDK atau Chrome (untuk web)
- Git (opsional) untuk manajemen versi

## Backend (CodeIgniter 4)
1. Masuk ke folder `backend-ci4/`.
2. Salin berkas `env` menjadi `.env`, aktifkan dan isi konfigurasi penting:
   - `app.baseURL = 'http://localhost:8080'` (atau alamat server Anda)
   - Konfigurasi database (hostname, username, password, database, driver)
3. Instal dependensi (jika vendor belum ada atau ingin menyegarkan):
   - `composer install`
4. Jalankan server pengembangan:
   - `php spark serve` (default di http://localhost:8080)
5. Pastikan endpoint API terbuka di `{baseURL}/api/...` sesuai route Anda.

## Frontend (Flutter)
1. Masuk ke folder `frontend_flutter/`.
2. Unduh dependensi: `flutter pub get`.
3. Jalankan aplikasi: `flutter run` (pilih device/emulator/Chrome). Untuk web: `flutter run -d chrome`.
4. Atur Base URL API:
   - Buka menu `Settings` di aplikasi.
   - Isi `Base URL` dengan alamat backend, misal `http://192.168.78.2:8080/api` (sesuaikan IP/port).
   - Simpan. Nilai ini disimpan di `shared_preferences` dan digunakan oleh `ApiService`.

## Menguji sinkronisasi & health check
1. Pastikan backend sedang berjalan dan dapat diakses dari device/emulator (periksa jaringan dan firewall).
2. Di aplikasi, buka Status Sinkronisasi (ikon info ➜ Status):
   - Tekan `Cek Health` untuk memastikan API hidup. Pesan ramah akan muncul (hijau bila sukses, merah bila gagal).
3. Tekan tombol sinkron (ikon sync) untuk push/pull data. Kesalahan akan ditampilkan dengan pesan yang diformat dan dicatat di Riwayat Error Log.
4. Lihat log error: menu ⋮ ➜ `Riwayat Error Log` untuk detail (pesan ramah + raw error).

## Mode offline
- Data disimpan di SQLite lokal; pengguna tetap bisa membuat/mengelola transaksi.
- Saat online kembali, tekan sinkron agar perubahan lokal dikirim ke server dan data server ditarik ke lokal.

## Pengaturan penting
- Ubah default base URL di `lib/data/remote/api_service.dart` jika ingin nilai bawaan berbeda.
- Token/otorisasi (jika diperlukan) bisa disetel di `ApiService` atau disimpan via Settings (lihat implementasi token di proyek Anda).

## Troubleshooting singkat
- Tidak bisa akses API: periksa IP/port di Settings, pastikan emulator dapat menjangkau host (gunakan IP LAN, bukan localhost untuk emulator).
- Health check merah: lihat Riwayat Error Log untuk raw error, pastikan backend berjalan dan CORS/Firewall aman.
- Sinkron tidak jalan: pastikan ada koneksi internet, cek token/otorisasi, dan pastikan skema DB backend sesuai dengan model API.
