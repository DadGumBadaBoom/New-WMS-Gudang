# Dokumentasi API Endpoints

Dokumentasi lengkap REST API untuk WMS Gudang (CodeIgniter 4 Backend).

**Base URL**: `http://localhost:8080/api` (sesuaikan dengan environment Anda)

**Authentication**: Semua endpoint memerlukan filter `apitoken`. Tambahkan header atau konfigurasi token sesuai kebutuhan sistem Anda.

---

## 1. Health Check

### GET `/api/health`

Memeriksa status server dan koneksi database.

**Request:**
```http
GET /api/health HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "db": "ok",
  "time": "2026-01-12T10:30:00+00:00",
  "last_sync": {
    "device_id": "device-123",
    "table_name": "barang",
    "record_id": 5,
    "action": "update",
    "sync_at": "2026-01-12 10:25:00"
  }
}
```

**Response Fields:**
- `status`: Status server (`ok` atau `error`)
- `db`: Status koneksi database (`ok` atau `error`)
- `time`: Waktu server saat ini (ISO 8601)
- `last_sync`: Log sinkronisasi terakhir (null jika belum ada)

---

## 2. Barang (Master Data)

### GET `/api/barang`

Ambil daftar barang dengan paginasi dan pencarian.

**Query Parameters:**
- `q` (optional): Keyword pencarian (kode_barang atau nama_barang)
- `per_page` (optional): Jumlah data per halaman (default: 20)
- `page` (optional): Nomor halaman (default: 1)

**Request Example:**
```http
GET /api/barang?q=laptop&per_page=10&page=1 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Laptop Dell XPS 13",
      "satuan": "Unit",
      "stok_saat_ini": 15,
      "harga_beli": 12000000,
      "harga_jual": 15000000,
      "kategori": "Elektronik",
      "created_at": "2026-01-10 08:00:00",
      "updated_at": "2026-01-12 09:30:00"
    }
  ],
  "pager": {
    "pageCount": 3,
    "currentPage": 1,
    "perPage": 10,
    "total": 25
  }
}
```

---

### GET `/api/barang/{id}`

Ambil detail barang berdasarkan ID.

**Request:**
```http
GET /api/barang/1 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "id": 1,
  "kode_barang": "BRG-001",
  "nama_barang": "Laptop Dell XPS 13",
  "satuan": "Unit",
  "stok_saat_ini": 15,
  "harga_beli": 12000000,
  "harga_jual": 15000000,
  "kategori": "Elektronik",
  "created_at": "2026-01-10 08:00:00",
  "updated_at": "2026-01-12 09:30:00"
}
```

**Response (404 Not Found):**
```json
{
  "status": 404,
  "error": 404,
  "messages": {
    "error": "Barang tidak ditemukan"
  }
}
```

---

### POST `/api/barang`

Tambah barang baru.

**Request Body:**
```json
{
  "kode_barang": "BRG-002",
  "nama_barang": "Mouse Logitech MX Master 3",
  "satuan": "Unit",
  "stok_saat_ini": 50,
  "harga_beli": 1200000,
  "harga_jual": 1500000,
  "kategori": "Aksesoris"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "kode_barang": "BRG-002",
  "nama_barang": "Mouse Logitech MX Master 3",
  "satuan": "Unit",
  "stok_saat_ini": 50,
  "harga_beli": 1200000,
  "harga_jual": 1500000,
  "kategori": "Aksesoris",
  "created_at": "2026-01-12 10:00:00",
  "updated_at": "2026-01-12 10:00:00"
}
```

**Response (400 Validation Error):**
```json
{
  "status": 400,
  "error": 400,
  "messages": {
    "kode_barang": "Kode barang sudah digunakan",
    "nama_barang": "Nama barang wajib diisi"
  }
}
```

---

### PUT `/api/barang/{id}`

Update data barang.

**Request:**
```http
PUT /api/barang/1 HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "nama_barang": "Laptop Dell XPS 13 (Updated)",
  "harga_jual": 16000000
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "kode_barang": "BRG-001",
  "nama_barang": "Laptop Dell XPS 13 (Updated)",
  "satuan": "Unit",
  "stok_saat_ini": 15,
  "harga_beli": 12000000,
  "harga_jual": 16000000,
  "kategori": "Elektronik",
  "created_at": "2026-01-10 08:00:00",
  "updated_at": "2026-01-12 10:15:00"
}
```

---

### DELETE `/api/barang/{id}`

Hapus barang (soft delete).

**Request:**
```http
DELETE /api/barang/1 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "message": "Barang dihapus"
}
```

---

## 3. Stok

### GET `/api/stok`

Ambil daftar stok dengan filter barang_id.

**Query Parameters:**
- `barang_id` (optional): Filter berdasarkan ID barang
- `per_page` (optional): Jumlah data per halaman (default: 20)
- `page` (optional): Nomor halaman (default: 1)

**Request Example:**
```http
GET /api/stok?barang_id=1&per_page=20&page=1 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "barang_id": 1,
      "jumlah": 15,
      "lokasi_gudang": "Gudang A - Rak 3",
      "created_at": "2026-01-10 08:00:00",
      "updated_at": "2026-01-12 09:30:00"
    }
  ],
  "pager": {
    "pageCount": 1,
    "currentPage": 1,
    "perPage": 20,
    "total": 1
  }
}
```

---

### GET `/api/stok/{id}`

Ambil detail stok berdasarkan ID.

**Response:** Sama seperti GET barang, format sesuai struktur tabel stok.

---

### POST `/api/stok`

Tambah entri stok baru dan update stok_saat_ini di tabel barang.

**Request Body:**
```json
{
  "barang_id": 1,
  "jumlah": 20,
  "lokasi_gudang": "Gudang B - Rak 5"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "barang_id": 1,
  "jumlah": 20,
  "lokasi_gudang": "Gudang B - Rak 5",
  "created_at": "2026-01-12 10:30:00",
  "updated_at": "2026-01-12 10:30:00"
}
```

**Catatan:** Stok di tabel barang akan otomatis diupdate menjadi `jumlah` yang diinput.

---

### PUT `/api/stok/{id}`

Update stok dan sinkronkan dengan master barang.

**Response:** Struktur sama dengan POST, dengan updated_at terbaru.

---

### DELETE `/api/stok/{id}`

Hapus entri stok.

**Response (200 OK):**
```json
{
  "message": "Stok dihapus"
}
```

---

## 4. Transaksi Masuk

### GET `/api/transaksi-masuk`

Ambil daftar transaksi masuk dengan filter tanggal, barang, dan pencarian.

**Query Parameters:**
- `barang_id` (optional): Filter berdasarkan ID barang
- `tanggal_from` (optional): Filter tanggal mulai (format: YYYY-MM-DD)
- `tanggal_to` (optional): Filter tanggal sampai (format: YYYY-MM-DD)
- `q` (optional): Keyword pencarian kode_transaksi
- `per_page` (optional): Jumlah data per halaman (default: 20)
- `page` (optional): Nomor halaman (default: 1)

**Request Example:**
```http
GET /api/transaksi-masuk?tanggal_from=2026-01-01&tanggal_to=2026-01-31&per_page=20 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "kode_transaksi": "TM-20260112-001",
      "barang_id": 1,
      "jumlah": 10,
      "tanggal": "2026-01-12",
      "supplier": "PT Maju Jaya",
      "catatan": "Pembelian bulanan",
      "created_at": "2026-01-12 08:00:00",
      "updated_at": "2026-01-12 08:00:00"
    }
  ],
  "pager": {
    "pageCount": 1,
    "currentPage": 1,
    "perPage": 20,
    "total": 5
  }
}
```

---

### GET `/api/transaksi-masuk/{id}`

Ambil detail transaksi masuk berdasarkan ID.

---

### POST `/api/transaksi-masuk`

Tambah transaksi masuk baru. **Otomatis menambah stok barang.**

**Request Body:**
```json
{
  "kode_transaksi": "TM-20260112-002",
  "barang_id": 1,
  "jumlah": 15,
  "tanggal": "2026-01-12",
  "supplier": "PT Sukses Sentosa",
  "catatan": "Stok tambahan"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "kode_transaksi": "TM-20260112-002",
  "barang_id": 1,
  "jumlah": 15,
  "tanggal": "2026-01-12",
  "supplier": "PT Sukses Sentosa",
  "catatan": "Stok tambahan",
  "created_at": "2026-01-12 10:45:00",
  "updated_at": "2026-01-12 10:45:00"
}
```

**Efek Samping:**
- Stok di `barang.stok_saat_ini` bertambah sebesar `jumlah`
- Tabel `stok` akan di-upsert dengan jumlah baru

---

### PUT `/api/transaksi-masuk/{id}`

Update transaksi masuk dan sesuaikan stok berdasarkan selisih jumlah lama vs baru.

**Request:**
```http
PUT /api/transaksi-masuk/1 HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "jumlah": 20,
  "catatan": "Jumlah dikoreksi"
}
```

**Response:** Struktur sama dengan POST.

**Efek Samping:**
- Stok akan disesuaikan: `stok_baru = stok_lama - jumlah_lama + jumlah_baru`

---

### DELETE `/api/transaksi-masuk/{id}`

Hapus transaksi masuk dan kurangi stok barang sesuai jumlah transaksi.

**Response (200 OK):**
```json
{
  "message": "Transaksi masuk dihapus"
}
```

**Efek Samping:**
- Stok dikurangi sebesar `jumlah` transaksi yang dihapus

---

## 5. Transaksi Keluar

### GET `/api/transaksi-keluar`

Ambil daftar transaksi keluar dengan filter tanggal, barang, dan pencarian.

**Query Parameters:** Sama seperti transaksi-masuk.

**Response:** Struktur sama dengan transaksi-masuk, field sesuai tabel transaksi_keluar.

---

### GET `/api/transaksi-keluar/{id}`

Ambil detail transaksi keluar.

---

### POST `/api/transaksi-keluar`

Tambah transaksi keluar baru. **Otomatis mengurangi stok barang.**

**Request Body:**
```json
{
  "kode_transaksi": "TK-20260112-001",
  "barang_id": 1,
  "jumlah": 5,
  "tanggal": "2026-01-12",
  "pelanggan": "Toko ABC",
  "catatan": "Penjualan retail"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "kode_transaksi": "TK-20260112-001",
  "barang_id": 1,
  "jumlah": 5,
  "tanggal": "2026-01-12",
  "pelanggan": "Toko ABC",
  "catatan": "Penjualan retail",
  "created_at": "2026-01-12 11:00:00",
  "updated_at": "2026-01-12 11:00:00"
}
```

**Response (400 Validation Error):**
```json
{
  "status": 400,
  "error": 400,
  "messages": {
    "stok": "Stok tidak mencukupi"
  }
}
```

**Efek Samping:**
- Stok di `barang.stok_saat_ini` berkurang sebesar `jumlah`
- Tabel `stok` akan di-upsert dengan jumlah baru

---

### PUT `/api/transaksi-keluar/{id}`

Update transaksi keluar dan sesuaikan stok berdasarkan selisih.

**Validasi:** Stok harus mencukupi untuk perubahan jumlah.

---

### DELETE `/api/transaksi-keluar/{id}`

Hapus transaksi keluar dan kembalikan stok barang.

**Response (200 OK):**
```json
{
  "message": "Transaksi keluar dihapus"
}
```

**Efek Samping:**
- Stok bertambah kembali sebesar `jumlah` transaksi yang dihapus

---

## 6. Sinkronisasi

### POST `/api/sync/push`

Kirim (push) data lokal ke server. Endpoint ini menerima multiple entities sekaligus.

**Request Body:**
```json
{
  "device_id": "device-abc123",
  "barang": [
    {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Laptop Dell",
      "stok_saat_ini": 10
    }
  ],
  "stok": [],
  "transaksi_masuk": [
    {
      "id": 5,
      "kode_transaksi": "TM-001",
      "barang_id": 1,
      "jumlah": 5,
      "tanggal": "2026-01-12"
    }
  ],
  "transaksi_keluar": []
}
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "barang_disimpan": [1],
  "stok_disimpan": [],
  "masuk_disimpan": [5],
  "keluar_disimpan": []
}
```

**Response (400/500 Error):**
```json
{
  "status": 400,
  "error": 400,
  "messages": {
    "error": "{\"kode_transaksi\": \"Kode transaksi sudah ada\"}"
  }
}
```

**Catatan:**
- Jika `id` ada dan record ditemukan di server, data akan diupdate.
- Jika `id` tidak ada atau tidak ditemukan, record baru akan dibuat.
- Log sinkronisasi dicatat ke tabel `sync_log` dengan `device_id`, `table_name`, `record_id`, dan `action`.

---

### GET `/api/sync/pull`

Tarik (pull) data terbaru dari server.

**Query Parameters:**
- `updated_after` (optional): Filter data yang diupdate setelah timestamp ini (format: YYYY-MM-DD HH:mm:ss)
- `per_page` (optional): Jumlah data per halaman (default: 200)
- `page` (optional): Nomor halaman (default: 1)

**Request Example:**
```http
GET /api/sync/pull?updated_after=2026-01-12%2009:00:00&per_page=100&page=1 HTTP/1.1
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "barang": [
    {
      "id": 1,
      "kode_barang": "BRG-001",
      "nama_barang": "Laptop Dell",
      "stok_saat_ini": 15,
      "updated_at": "2026-01-12 10:30:00"
    }
  ],
  "barang_pager": {
    "pageCount": 1,
    "currentPage": 1,
    "perPage": 100,
    "total": 1
  },
  "stok": [],
  "stok_pager": {
    "pageCount": 0,
    "currentPage": 1,
    "perPage": 100,
    "total": 0
  },
  "transaksi_masuk": [],
  "transaksi_masuk_pager": {
    "pageCount": 0,
    "currentPage": 1,
    "perPage": 100,
    "total": 0
  },
  "transaksi_keluar": [],
  "transaksi_keluar_pager": {
    "pageCount": 0,
    "currentPage": 1,
    "perPage": 100,
    "total": 0
  }
}
```

**Catatan:**
- Response berisi semua entities (barang, stok, transaksi_masuk, transaksi_keluar) dengan pager masing-masing.
- Client dapat menggunakan `updated_after` untuk incremental sync (hanya data yang berubah sejak sync terakhir).

---

### POST `/api/sync/batch`

Gabungan push + pull dalam satu request. Sangat efisien untuk sinkronisasi penuh.

**Request Body:** Sama seperti `/api/sync/push`

**Response:** Hasil push akan divalidasi terlebih dahulu, lalu diikuti dengan response pull.

**Response (200 OK):**
```json
{
  "status": "ok",
  "barang": [...],
  "barang_pager": {...},
  "stok": [...],
  "stok_pager": {...},
  "transaksi_masuk": [...],
  "transaksi_masuk_pager": {...},
  "transaksi_keluar": [...],
  "transaksi_keluar_pager": {...}
}
```

**Catatan:**
- Jika push gagal, endpoint ini akan mengembalikan error push tanpa melakukan pull.
- Jika push sukses, langsung dilanjutkan dengan pull data terbaru.

---

## 7. Deletion Sync (Upcoming)

### POST `/api/sync/deletions`

Kirim log penghapusan data dari client ke server. Endpoint ini digunakan untuk menghapus data di server berdasarkan `server_id` yang dicatat di deletion_log client.

**Request Body:**
```json
{
  "deletions": [
    {
      "entity_type": "barang",
      "server_id": 5,
      "kode": "BRG-005",
      "nama": "Monitor LG 27 inch",
      "deleted_at": "2026-01-12T10:45:00Z"
    },
    {
      "entity_type": "transaksi_masuk",
      "server_id": 12,
      "kode": "TM-20260110-003",
      "nama": "",
      "deleted_at": "2026-01-12T11:00:00Z"
    }
  ]
}
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "deleted_count": 2,
  "results": [
    {
      "entity_type": "barang",
      "server_id": 5,
      "status": "deleted"
    },
    {
      "entity_type": "transaksi_masuk",
      "server_id": 12,
      "status": "deleted"
    }
  ]
}
```

**Response (404 Not Found):**
Jika endpoint belum diimplementasi di backend, client akan menerima 404 dan otomatis menandai deletions sebagai synced untuk mencegah retry loop.

**Implementasi Backend:**
Lihat dokumentasi lengkap di [backend-deletion-endpoint.md](backend-deletion-endpoint.md) untuk contoh implementasi controller CI4.

---

## Error Handling

Semua endpoint menggunakan format error standar CodeIgniter 4:

**4xx Client Errors:**
```json
{
  "status": 400,
  "error": 400,
  "messages": {
    "field_name": "Pesan error untuk field tertentu",
    "error": "Pesan error umum"
  }
}
```

**5xx Server Errors:**
```json
{
  "status": 500,
  "error": 500,
  "messages": {
    "error": "Gagal memproses request"
  }
}
```

**Common Status Codes:**
- `200 OK`: Request berhasil
- `201 Created`: Resource berhasil dibuat
- `400 Bad Request`: Validasi gagal atau payload salah
- `401 Unauthorized`: Token API tidak valid atau tidak ada
- `404 Not Found`: Resource tidak ditemukan
- `500 Internal Server Error`: Error server (cek log backend)

---

## Testing dengan cURL

### Health Check
```bash
curl -X GET http://localhost:8080/api/health
```

### Get Barang List
```bash
curl -X GET "http://localhost:8080/api/barang?q=laptop&per_page=10"
```

### Create Barang
```bash
curl -X POST http://localhost:8080/api/barang \
  -H "Content-Type: application/json" \
  -d '{
    "kode_barang": "BRG-999",
    "nama_barang": "Test Item",
    "satuan": "Unit",
    "stok_saat_ini": 0
  }'
```

### Push Sync
```bash
curl -X POST http://localhost:8080/api/sync/push \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device",
    "barang": [
      {
        "id": 1,
        "kode_barang": "BRG-001",
        "nama_barang": "Updated Name",
        "stok_saat_ini": 20
      }
    ],
    "stok": [],
    "transaksi_masuk": [],
    "transaksi_keluar": []
  }'
```

### Pull Sync
```bash
curl -X GET "http://localhost:8080/api/sync/pull?per_page=50&page=1"
```

---

## Testing dengan PowerShell

### Health Check
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method Get
```

### Get Barang
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/api/barang?per_page=10" -Method Get
```

### Create Barang
```powershell
$body = @{
  kode_barang = "BRG-TEST"
  nama_barang = "PowerShell Test"
  satuan = "Unit"
  stok_saat_ini = 0
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/barang" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

### Push Sync
```powershell
$syncData = @{
  device_id = "ps-device"
  barang = @(
    @{
      id = 1
      kode_barang = "BRG-001"
      nama_barang = "Updated via PS"
      stok_saat_ini = 25
    }
  )
  stok = @()
  transaksi_masuk = @()
  transaksi_keluar = @()
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "http://localhost:8080/api/sync/push" `
  -Method Post `
  -ContentType "application/json" `
  -Body $syncData
```

---

## Catatan Penting

1. **Authentication**: Pastikan konfigurasi filter `apitoken` di `app/Config/Filters.php` sesuai dengan kebutuhan sistem. Tambahkan validasi token di middleware jika diperlukan.

2. **CORS**: Jika frontend diakses dari domain berbeda (misalnya saat development Flutter web), pastikan CORS diaktifkan di `app/Config/Cors.php`.

3. **Timestamps**: Semua field `created_at` dan `updated_at` menggunakan timestamp database dan otomatis dikelola oleh CodeIgniter Model.

4. **Soft Delete**: Controller menggunakan `delete()` yang akan melakukan soft delete jika model dikonfigurasi dengan `useSoftDeletes = true`.

5. **Transaction Safety**: Endpoint transaksi masuk/keluar menggunakan database transaction untuk memastikan konsistensi data antara tabel transaksi dan stok.

6. **Pagination**: Default limit adalah 20 records per page untuk endpoint list (barang, stok, transaksi). Untuk sync pull, default adalah 200 untuk efisiensi.

7. **Sync Strategy**: 
   - Push: Client mengirim perubahan lokal (upsert by ID)
   - Pull: Client menarik data berdasarkan `updated_after` timestamp
   - Batch: Push + Pull dalam satu request (efisien)

8. **Deletion Sync**: Endpoint `/api/sync/deletions` masih perlu diimplementasi di backend. Lihat [backend-deletion-endpoint.md](backend-deletion-endpoint.md) untuk panduan lengkap.

---

## Referensi

- [Getting Started](getting-started.md) - Panduan instalasi dan setup
- [Architecture](architecture.md) - Arsitektur sistem dan alur data
- [Backend Deletion Endpoint](backend-deletion-endpoint.md) - Implementasi endpoint deletion sync
- [Testing](testing.md) - Panduan testing API
- [Troubleshooting](troubleshooting.md) - Solusi masalah umum
- [Changelog](changelog.md) - Riwayat perubahan sistem

---

**Versi Dokumentasi**: 1.0.0  
**Tanggal Update**: 12 Januari 2026  
**Status**: Production Ready (kecuali deletion sync endpoint)
