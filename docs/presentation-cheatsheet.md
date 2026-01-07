# Cheat Sheet Presentasi (REST + SQLite)

Gunakan poin-poin ini untuk menjelaskan sistem ke dosen dalam 5–10 menit.

## 1) Apa yang dibangun
- Sistem WMS gudang offline-first: Flutter di device, backend REST CodeIgniter 4.
- Data harian disimpan di SQLite lokal; server dipakai untuk konsolidasi & backup.

## 2) Mengapa kombinasi REST + SQLite
- **Reliabilitas**: REST standar memudahkan integrasi; SQLite memastikan app tetap jalan saat offline.
- **Kinerja**: Query lokal cepat, hemat jaringan; sinkron hanya mengirim delta/pending.
- **Portabilitas**: Satu codebase Flutter untuk Android/iOS/web/desktop; API dapat di-host di mana saja.

## 3) Arsitektur singkat
- Frontend: Flutter + Dio (REST client), SQLite (sqflite), shared_preferences (config), connectivity_plus.
- Backend: CodeIgniter 4 REST API; endpoint health, CRUD barang/transaksi, autentikasi (token/JWT sesuai konfigurasi).
- Konfigurasi dinamis: Base URL bisa diubah di menu Settings, disimpan lokal.

## 4) Alur utama yang perlu dijelaskan
- **Health Check**: tombol "Cek Health" ➜ panggil endpoint `/api/health` ➜ tampilkan status atau pesan ramah jika gagal.
- **Offline CRUD**: user tambah/ubah transaksi; data masuk SQLite dan diberi flag pending.
- **Sinkronisasi**:
  1. Push: kirim data pending ke REST API, tandai sukses di SQLite.
  2. Pull: tarik data terbaru server untuk menyegarkan cache lokal.
  3. Error: diformat ramah, dicatat di Riwayat Error Log (dengan raw detail untuk debugging).

## 5) Demo pendek (urutan)
1. Tunjukkan Settings: set Base URL API (contoh IP LAN backend).
2. Tekan "Cek Health" ➜ lihat indikator hijau/merah.
3. Matikan jaringan, buat transaksi baru ➜ tunjukkan tetap tersimpan (offline).
4. Nyalakan jaringan, tekan sinkron ➜ perubahan terkirim, data server masuk.
5. Buka Riwayat Error Log jika ada kegagalan untuk menunjukkan transparansi error.

## 6) Topik tanya-jawab yang umum
- **Keamanan**: token di header (bisa JWT), HTTPS saat produksi.
- **Konsistensi**: flag pending + urutan push/pull; server sebagai sumber kebenaran.
- **Konflik data**: strategi dapat dipilih (last-write-wins atau merge khusus) di repository.
- **Skalabilitas**: REST stateless, bisa ditaruh di VM/container; Flutter tetap sama.
- **Port offline**: SQLite bawaan perangkat, tidak butuh server lokal.

## 7) Diagram alur (tekstual)
Device (Flutter)
→ CRUD lokal (SQLite, tandai pending)
→ Sinkron: push pending → REST API (CI4) → DB server
→ Pull data terkini → perbarui SQLite
→ UI menampilkan status/health/error log
