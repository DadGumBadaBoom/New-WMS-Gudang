# Arsitektur & Alur Sistem

## Gambaran umum
- **Frontend**: Flutter (Android/iOS/web/desktop) dengan pola offline-first. Data utama disimpan di SQLite lokal; sinkronisasi memakai REST API.
- **Backend**: CodeIgniter 4 menyediakan Full REST API untuk data gudang (barang, transaksi masuk/keluar, dll.).
- **Konfigurasi dinamis**: Base URL API dapat diubah dari menu Settings (disimpan di `shared_preferences`). Default ada di `lib/data/remote/api_service.dart`.

## Komponen utama
- **API Service (Dio)**: Membungkus request REST dengan base URL yang bisa diubah, menangani token/headers.
- **Repository sinkronisasi**: Menyelaraskan data lokal (SQLite) dengan server (push perubahan lokal, pull pembaruan server).
- **SQLite (sqflite)**: Penyimpanan lokal untuk entitas utama (barang, transaksi masuk/keluar) plus status sinkron.
- **UI & State**: Halaman utama dengan tab barang/masuk/keluar, tombol sinkron, health check, dan riwayat error.
- **Error logging**: Setiap error disimpan dengan timestamp, pesan ramah, dan raw error untuk troubleshooting (Riwayat Error Log).

## Alur data utama
1) **Health Check**
   - User tekan `Cek Health` ➜ panggil endpoint health backend.
   - Respons 200 menampilkan status server/DB/waktu.
   - Gagal koneksi/time-out menghasilkan pesan ramah (contoh: "Server tidak dapat diakses...").

2) **Sinkronisasi (push/pull)**
   - **Push**: Perubahan lokal (pending) dikirim ke API. Bila sukses, penanda sinkron diperbarui di SQLite.
   - **Pull**: Data terbaru dari API ditarik dan menimpa cache lokal secara aman (merge/replace sesuai aturan repo).
   - Error apa pun diformat ramah + dicatat (termasuk raw error) untuk audit.

3) **Mode offline**
   - Semua CRUD dilakukan ke SQLite terlebih dahulu.
   - Tanpa koneksi, data tetap tersedia; perubahan ditandai pending.
   - Saat online, pengguna menekan sinkron untuk mengirim pending dan menarik data terbaru.

## Penyimpanan & status
- **SQLite**: Tabel master & transaksi, plus flag/status sinkronisasi.
- **Shared Preferences**: Base URL API, token/config ringan.
- **In-memory**: Status health terkini, error terakhir, riwayat error (dibatasi 50 entri terbaru).

## Penanganan error
- Fungsi `_formatErrorMessage` mengubah error teknis (connection refused, timeout, route to host, socket, unauthorized) menjadi pesan ramah.
- UI menampilkan pesan singkat berwarna (hijau sukses, merah gagal); detail raw tersedia di Riwayat Error Log untuk debugging.
- Health check & sinkronisasi menggunakan pola yang sama: format ➜ tampilkan ➜ log.

## Konfigurasi & extensibility
- Ganti base URL via Settings (persisten). Untuk default baru, ubah `ApiService`.
- Tambah entitas baru: definisikan model lokal, DAO SQLite, endpoint API, dan logika sinkron di repository.
- Keamanan/token: sisipkan header di `ApiService` atau simpan token di preferences lalu gunakan pada setiap request.

## Deployment singkat
- Backend: jalankan di server PHP (Nginx/Apache) atau `php spark serve` untuk dev; pastikan `public/` jadi doc root.
- Frontend: build sesuai target (`flutter build apk`, `flutter build appbundle`, `flutter build web`, dll.). Pastikan Base URL mengarah ke host backend yang dapat diakses perangkat.
