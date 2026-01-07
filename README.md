# WMS Gudang — Offline‑First (REST API + SQLite)

Sistem manajemen gudang dengan arsitektur offline‑first: aplikasi Flutter menyimpan data lokal di SQLite dan melakukan sinkronisasi aman ke REST API CodeIgniter 4. Dirancang agar tetap berjalan lancar walau koneksi internet tidak stabil.

## Ringkas Fitur
- Offline‑first: data tersimpan lokal, sinkron otomatis saat online
- REST API modular berbasis CodeIgniter 4
- Sinkronisasi push/pull transaksi masuk/keluar & stok
- Multi‑platform: Android, iOS, Web, Windows, macOS, Linux

## Susunan Repo
- [backend-ci4](backend-ci4/): REST API (PHP, CodeIgniter 4)
- [frontend_flutter](frontend_flutter/): Aplikasi Flutter + SQLite
- [docs](docs/): Panduan memulai, arsitektur, testing, dan lainnya

## Mulai Cepat (Windows)

### Backend (CodeIgniter 4)
Prasyarat: PHP 8+, Composer, opsi XAMPP (opsional).

Opsi A — Jalankan server dev (spark):

```powershell
cd backend-ci4
copy env .env
composer install
php spark serve
```

Server dev berjalan di http://localhost:8080. Atur kredensial DB dan base URL di `.env` sesuai kebutuhan.

Opsi B — Via XAMPP/Apache:
- Set DocumentRoot ke folder `backend-ci4/public`
- Pastikan `public/index.php` dapat diakses (contoh: http://localhost/backend)

### Frontend (Flutter)
Prasyarat: Flutter SDK 3.x terpasang.

```powershell
cd frontend_flutter
flutter pub get
flutter run -d windows   # atau -d chrome / -d android
```

- Atur API Base URL di menu Settings dalam aplikasi.
- Nilai default di kode: `http://192.168.78.2:8080/api` — ubah sesuai alamat backend Anda.

## Dokumentasi
- Panduan memulai: [docs/getting-started.md](docs/getting-started.md)
- Arsitektur & alur: [docs/architecture.md](docs/architecture.md)
- Testing API: [docs/testing.md](docs/testing.md)
- Changelog: [docs/changelog.md](docs/changelog.md)
- Cheat‑sheet presentasi: [docs/presentation-cheatsheet.md](docs/presentation-cheatsheet.md)

## Teknologi
- Backend: CodeIgniter 4 (REST), konfigurasi `.env`, dukungan MySQL/SQL Server
- Frontend: Flutter 3.x, `dio` (HTTP), `sqflite` (SQLite), `shared_preferences`, `connectivity_plus`

## Pengujian & Kontribusi
- Backend: jalankan `php spark serve`, uji endpoint dengan Postman/Insomnia.
- Frontend: `flutter test` untuk unit/widget (jika tersedia), uji sinkronisasi dengan Base URL ke server lokal.

Butuh detail lebih lanjut? Lihat folder [docs](docs/).
