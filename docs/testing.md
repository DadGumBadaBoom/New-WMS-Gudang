# Panduan Testing API (Windows)

Cara cepat menguji backend REST API dengan `curl` dan PowerShell tanpa perlu membuka app Flutter.

## Persiapan
- Pastikan backend berjalan, idealnya dengan binding ke semua interface agar bisa diakses dari device/emulator:

```bash
php spark serve --host 0.0.0.0 --port 8080
```

- Tentukan IP host di LAN, misal `192.168.78.2`. Ganti di contoh perintah di bawah.

## Uji Health Endpoint
- `curl` (verbose):

```bash
curl -v http://192.168.78.2:8080/api/health
```

- PowerShell `Invoke-RestMethod`:

```powershell
Invoke-RestMethod -Method GET -Uri "http://192.168.78.2:8080/api/health"
```

- Cek konektivitas port:

```powershell
Test-NetConnection -ComputerName 192.168.78.2 -Port 8080
```

Ekspektasi sukses: JSON seperti `{ "status": "ok", "db": "ok", "time": "..." }`.

## Uji POST (contoh transaksi masuk)
- `curl`:

```bash
curl -v -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "kode_barang": "BRG-001",
    "jumlah": 5,
    "tanggal": "2026-01-07T10:00:00Z",
    "catatan": "uji sinkron"
  }' \
  http://192.168.78.2:8080/api/transaksi-masuk
```

- PowerShell `Invoke-RestMethod`:

```powershell
$body = {
  kode_barang = "BRG-001"
  jumlah      = 5
  tanggal     = "2026-01-07T10:00:00Z"
  catatan     = "uji sinkron"
} | ConvertTo-Json

Invoke-RestMethod -Method POST `
  -Uri "http://192.168.78.2:8080/api/transaksi-masuk" `
  -Headers @{ 'Content-Type' = 'application/json'; 'Authorization' = 'Bearer <token>' } `
  -Body $body
```

## Debug lanjutan
- Timeout simulasi (curl):

```bash
curl --connect-timeout 3 http://192.168.78.2:8081/api/health
```

- Lihat header/CORS (curl):

```bash
curl -I -H "Origin: http://localhost:3000" http://192.168.78.2:8080/api/health
```

- Trace lengkap (curl):

```bash
curl -v http://192.168.78.2:8080/api/health 2>&1 | Out-File -FilePath curl-health.log
```

## Tips konektivitas emulator/device
- Gunakan IP LAN host (bukan `localhost`). Untuk Android emulator, `10.0.2.2` bisa dipakai jika backend berjalan di host yang sama.
- Pastikan firewall mengizinkan akses ke port 8080.
- Pastikan perangkat dan host berada di jaringan yang sama.

## Kaitkan dengan app Flutter
- Set Base URL di Settings app ke `http://192.168.78.2:8080/api`.
- Jika `curl`/PowerShell sukses tetapi app gagal, cek Riwayat Error Log di app untuk raw details.
