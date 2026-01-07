# Backend (CodeIgniter 4)

REST API untuk sistem Warehouse Management (WMS) yang digunakan oleh frontend Flutter offline-first. Berisi endpoint health, master data, dan transaksi (masuk/keluar) yang disinkronkan dengan SQLite di perangkat.

## Prasyarat

- PHP 8.1+ with `intl`, `mbstring`, `json`, `mysqlnd`, and `curl`
- Composer
- MySQL/MariaDB (or another configured database)
- Git (optional, for clone)

## Mulai cepat

1) Install dependencies:

```bash
composer install
```

2) Copy environment file and adjust settings:

```bash
cp env .env
```

Update `.env` for:
- `app.baseURL` (e.g. http://localhost:8080)
- Database credentials (`database.default.*`)

3) Run database migrations and seeders when available:

```bash
php spark migrate
php spark db:seed <SeederName>
```

4) Jalankan server lokal:

```bash
# Akses lokal saja
php spark serve

# Akses dari emulator/device (LAN binding)
php spark serve --host 0.0.0.0 --port 8080
```

The app serves from `public/` by default. Configure your web server (Nginx/Apache) to point to that folder in non-dev environments.

## Pengujian

```bash
php vendor/bin/phpunit
```

Quick test API (lihat juga docs/testing.md):

```bash
# Health
curl -v http://<host>:8080/api/health

# Contoh POST transaksi masuk (sesuaikan payload)
curl -v -X POST \
	-H "Content-Type: application/json" \
	-d '{"kode_barang":"BRG-001","jumlah":5}' \
	http://<host>:8080/api/transaksi-masuk
```

## Tugas umum

- Clear caches: `php spark cache:clear`
- Generate key (if needed): `php spark key:generate`
- Check routes: `php spark routes`

## Dokumentasi

- CodeIgniter 4 guide: https://codeigniter.com/user_guide/
- Project docs: lihat [../docs](../docs) untuk arsitektur, panduan memulai, testing, dan troubleshooting.

## Endpoint ringkas (contoh)
- `GET /api/health` — status server & DB
- `GET /api/barang` — daftar barang
- `POST /api/transaksi-masuk` — tambah transaksi masuk
- `POST /api/transaksi-keluar` — tambah transaksi keluar

Catatan: Sesuaikan nama/route aktual dengan implementasi controller Anda.
