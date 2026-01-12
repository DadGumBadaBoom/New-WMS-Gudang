# Troubleshooting

Ringkasan masalah umum yang pernah muncul selama pengembangan, beserta langkah pemecahan. Fokus pada error yang mengganggu jalannya aplikasi.

## 1) Health Check menampilkan error mentah (DioException)
- Gejala: Status Sinkronisasi menampilkan teks panjang "DioException ... route to host".
- Akar masalah: Repository health menangkap error dan mengembalikan string mentah.
- Perbaikan: `checkHealth()` sekarang melempar error untuk diformat di UI (lihat `lib/data/repository/sync_repository.dart`).
- Jika muncul lagi: pastikan Base URL benar, backend hidup, dan `_formatErrorMessage` mencakup pola error baru.

## 2) Tidak bisa terhubung ke server / Connection refused
- Gejala: Pesan ramah "Tidak dapat terhubung ke server" atau raw error connection refused.
- Langkah:
  1. Pastikan backend `php spark serve` berjalan dan port benar.
  2. Gunakan binding ke semua interface saat butuh diakses dari emulator/device: `php spark serve --host 0.0.0.0 --port 8080`.
  2. Di device/emulator, gunakan IP LAN (bukan `localhost`). Contoh: `http://192.168.x.x:8080/api`.
  3. Periksa firewall/antivirus yang memblokir port.
  4. Tes dengan browser/Postman dari device yang sama.

## 3) Timeout saat Health/Sinkron
- Gejala: Pesan "Koneksi ke server timeout".
- Langkah:
  1. Cek kestabilan jaringan/Wi-Fi.
  2. Pastikan server respons cepat (query DB tidak berat).
  3. Sesuaikan timeout Dio bila perlu (di ApiService) jika jaringan lambat.

## 4) No route to host / unreachable
- Gejala: Pesan "Server tidak dapat diakses. Periksa alamat IP server." atau raw SocketException no route to host.
- Langkah:
  1. Pastikan IP benar dan dalam satu segmen jaringan.
  2. Jika pakai emulator Android, gunakan IP host LAN, bukan 127.0.0.1.
  3. Cek router/VLAN yang memblokir akses antar perangkat.

## 5) Unauthorized / 401
- Gejala: Pesan "Akses ditolak. Periksa token API di Settings." atau status 401.
- Langkah:
  1. Pastikan token/credential dikirim di header (atur di ApiService/Settings).
  2. Cek aturan CORS/authorization di backend.
  3. Jika token tersimpan di preferences, hapus dan set ulang.

## 6) Sinkronisasi gagal (push/pull)
- Gejala: Pesan error saat tekan tombol sinkron; data pending tidak terkirim.
- Langkah:
  1. Cek koneksi dan Base URL (Settings).
  2. Buka Riwayat Error Log (menu ⋮ ➜ Riwayat Error Log) untuk melihat raw error.
  3. Pastikan skema API cocok dengan payload lokal (field wajib di backend).
  4. Periksa token/otorisasi jika backend memerlukan.
  5. Jika offline, tunggu koneksi stabil lalu ulangi sinkron.

## 6.1) Push Deletions mengembalikan 404
- Gejala: Error "Server tidak dapat diakses" atau 404 saat sinkron, tapi health check hijau.
- Akar masalah: Endpoint `/api/sync/deletions` belum dibuat di backend.
- Langkah:
  1. Implementasi endpoint di backend CI4 (lihat `docs/backend-deletion-endpoint.md`).
  2. Saat 404, frontend otomatis menandai deletion sebagai `is_synced=1` untuk mencegah retry loop.
  3. Setelah endpoint siap, data deletion log yang masih pending akan dikirim ulang.
  4. Pastikan backend menerima payload JSON: `{deletions: [{entity_type, server_id, deleted_at, ...}]}`

## 6.2) Data yang dihapus muncul lagi setelah pull
- Gejala: Hapus barang/transaksi lokal, pull dari server, data kembali muncul.
- Akar masalah: Pull tidak memeriksa deletion_log, sehingga data dari server di-insert ulang.
- Perbaikan: Sejak v0.4.0, pull otomatis skip data dengan `server_id` yang ada di deletion_log (30 hari terakhir).
- Pastikan:
  1. Database versi 4 (dengan kolom `is_synced`, `server_id` di deletion_log).
  2. Setiap hapus data harus menyimpan `server_id` ke deletion_log (bukan `entity_id` lokal).
  3. Backend juga menghapus data berdasarkan `server_id` saat menerima push deletions.

## 7) Health Check selalu merah meski server hidup
- Gejala: Health gagal padahal endpoint aktif.
- Langkah:
  1. Pastikan endpoint health sesuai dengan yang dipanggil di ApiService.
  2. Cek CORS atau middleware yang memblokir route health.
  3. Lihat raw error di Riwayat Error Log untuk detail HTTP status.

## 8) Base URL salah / tidak tersimpan
- Gejala: Setelah diubah di Settings, app masih memanggil URL lama.
- Langkah:
  1. Pastikan menekan tombol simpan di Settings.
  2. Tutup-buka app; nilai disimpan di `shared_preferences`.
  3. Periksa default di `lib/data/remote/api_service.dart`; ubah jika ingin default baru.

## 9) Data tidak muncul saat offline
- Gejala: Tidak ada data ketika koneksi diputus.
- Langkah:
  1. Pastikan SQLite terisi (lakukan sinkron pull minimal sekali saat online).
  2. Periksa DAO/queries lokal untuk tab terkait (barang/masuk/keluar).
  3. Jika tabel kosong, sinkron kembali setelah koneksi ada.

## 10) Riwayat Error Log tidak bertambah
- Gejala: Error tampil di UI tapi tidak masuk ke log riwayat.
- Langkah:
  1. Pastikan error ditangkap di try/catch dengan pemanggilan `_errorLogs.insert(...)`.
  2. Batas log 50 entri—entri lama akan terhapus.
  3. Cek apakah setState terpanggil (widget mounted) saat menambah log.

## 11) Emulator tidak bisa akses host
- Gejala: Connection refused hanya di emulator, bukan di laptop/PC.
- Langkah:
  1. Gunakan IP LAN host (contoh 192.168.x.x), bukan `localhost`.
  2. Untuk Android emulator, hindari 127.0.0.1; gunakan IP LAN atau 10.0.2.2 jika server di host yang sama.
  3. Pastikan firewall host mengizinkan akses dari emulator.

## 12) CORS atau HTTPS issue (jika deploy)
- Gejala: Request diblokir di browser (web build) atau error terkait sertifikat.
- Langkah:
  1. Aktifkan/konfigurasi CORS di backend CI4 untuk origin yang digunakan.
  2. Pastikan sertifikat HTTPS valid saat di produksi; untuk dev bisa gunakan HTTP atau sertifikat self-signed dengan pengecualian di Dio (hanya untuk pengujian).

## Tips umum
- Selalu cek Riwayat Error Log untuk raw details saat butuh debugging cepat.
- Uji dengan Postman/Insomnia langsung ke backend untuk memisahkan masalah frontend vs backend.
- Jika menambah jenis error baru, perluas `_formatErrorMessage` agar user mendapat pesan ramah.

## Lampiran: contoh konfigurasi & uji cepat
- Contoh `.env` backend (minimal):

  ```ini
  app.baseURL = 'http://localhost:8080'
  database.default.hostname = localhost
  database.default.database = wms
  database.default.username = root
  database.default.password = ''
  database.default.DBDriver = MySQLi
  # Jika pakai SQLSRV:
  # database.default.DBDriver = SQLSRV
  ```

- Contoh payload uji health (Postman/Insomnia):

  - Method: GET
  - URL: http://<host>:8080/api/health
  - Ekspektasi sukses: `{ "status": "ok", "db": "ok", "time": "..." }`

- Contoh payload uji sinkron (misal push transaksi masuk — sesuaikan field API):

  - Method: POST
  - URL: http://<host>:8080/api/transaksi-masuk
  - Headers: `Content-Type: application/json`, plus `Authorization: Bearer <token>` jika diperlukan.
  - Body (contoh sederhana):
    ```json
    {
      "kode_barang": "BRG-001",
      "jumlah": 5,
      "tanggal": "2026-01-07T10:00:00Z",
      "catatan": "uji sinkron"
    }
    ```

- Jika request di atas gagal, cocokkan pesan raw di Postman dengan Riwayat Error Log untuk mengetahui sisi mana yang bermasalah (backend atau frontend).
