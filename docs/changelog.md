# Changelog

Ringkasan perubahan sejak awal pengembangan.

## v0.4.0 — 2026-01-12
- **Deletion sync ke backend**: Data yang dihapus lokal kini dikirim ke server saat sync.
  - Tabel `deletion_log` bertambah kolom `is_synced` dan `server_id` (migrasi DB v3→v4).
  - Push deletions ke endpoint `/api/sync/deletions` sebelum push data lain.
  - Pull skip data yang sudah dihapus lokal (cek `serverId` di deletion log 30 hari terakhir).
  - Graceful handling untuk endpoint 404 (jika backend belum siap).
- Dokumentasi backend: panduan implementasi endpoint deletion di `docs/backend-deletion-endpoint.md`.

## v0.3.0 — 2026-01-07
- Health check lebih ramah: pesan diformat (timeout/koneksi/unauthorized) dan warna hijau/merah.
- Riwayat Error Log: simpan 50 entri terakhir (timestamp, pesan ramah, raw error) + tampilan di menu.
- Sinkron UI: AppBar dirapikan, tombol sinkron & status lebih jelas.

## v0.2.x
- Fondasi offline-first: SQLite untuk barang & transaksi, flag pending untuk sinkron.
- Repository sinkronisasi push/pull ke REST API menggunakan Dio.
- Settings untuk menyimpan Base URL API di shared_preferences.

## v0.1.x
- Inisialisasi proyek: CodeIgniter 4 app starter untuk backend, Flutter scaffold untuk frontend.
- API service dasar dengan base URL dan request REST.
