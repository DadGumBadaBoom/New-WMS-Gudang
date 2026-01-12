# Backend Endpoint: Sync Deletions

## Endpoint baru yang diperlukan

### POST /api/sync/deletions

Endpoint ini menerima list penghapusan dari client dan menghapus data terkait di database server.

#### Request

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <token>` (jika digunakan)

**Body:**
```json
{
  "deletions": [
    {
      "entity_type": "barang",
      "server_id": 123,
      "kode": "BRG-001",
      "nama": "Barang A",
      "deleted_at": "2026-01-12T10:30:00Z"
    },
    {
      "entity_type": "transaksi_masuk",
      "server_id": 456,
      "kode": "TRX-IN-001",
      "nama": "Transaksi Masuk A",
      "deleted_at": "2026-01-12T10:35:00Z"
    }
  ]
}
```

#### Response (Success)

**Status:** 200 OK

```json
{
  "status": "ok",
  "deleted_count": 2,
  "message": "2 item(s) berhasil dihapus"
}
```

#### Response (Partial Success)

**Status:** 200 OK

```json
{
  "status": "partial",
  "deleted_count": 1,
  "failed": [
    {
      "entity_type": "barang",
      "server_id": 999,
      "reason": "tidak ditemukan"
    }
  ],
  "message": "1 item berhasil, 1 item gagal"
}
```

#### Response (Error)

**Status:** 400/500

```json
{
  "status": "error",
  "message": "Gagal menghapus data"
}
```

## Implementasi Backend (CodeIgniter 4)

### 1. Route (app/Config/Routes.php)

```php
$routes->post('api/sync/deletions', 'SyncController::deletions');
```

### 2. Controller (app/Controllers/SyncController.php)

```php
<?php
namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class SyncController extends ResourceController
{
    protected $format = 'json';

    public function deletions()
    {
        $data = $this->request->getJSON(true);
        
        if (!isset($data['deletions']) || !is_array($data['deletions'])) {
            return $this->fail('Format tidak valid', 400);
        }

        $deletions = $data['deletions'];
        $deletedCount = 0;
        $failed = [];

        $db = \Config\Database::connect();

        foreach ($deletions as $deletion) {
            $entityType = $deletion['entity_type'] ?? '';
            $serverId = $deletion['server_id'] ?? null;

            if (!$serverId) {
                continue;
            }

            try {
                $table = $this->getTableName($entityType);
                if ($table) {
                    $result = $db->table($table)->delete(['id' => $serverId]);
                    if ($result) {
                        $deletedCount++;
                    } else {
                        $failed[] = [
                            'entity_type' => $entityType,
                            'server_id' => $serverId,
                            'reason' => 'tidak ditemukan'
                        ];
                    }
                }
            } catch (\Exception $e) {
                $failed[] = [
                    'entity_type' => $entityType,
                    'server_id' => $serverId,
                    'reason' => $e->getMessage()
                ];
            }
        }

        if (count($failed) > 0) {
            return $this->respond([
                'status' => 'partial',
                'deleted_count' => $deletedCount,
                'failed' => $failed,
                'message' => "$deletedCount item berhasil, " . count($failed) . " item gagal"
            ]);
        }

        return $this->respond([
            'status' => 'ok',
            'deleted_count' => $deletedCount,
            'message' => "$deletedCount item(s) berhasil dihapus"
        ]);
    }

    private function getTableName(string $entityType): ?string
    {
        $map = [
            'barang' => 'barang',
            'stok' => 'stok',
            'transaksi_masuk' => 'transaksi_masuk',
            'transaksi_keluar' => 'transaksi_keluar',
        ];

        return $map[$entityType] ?? null;
    }
}
```

## Catatan Penting

1. **Validasi**: Backend harus validasi bahwa `server_id` ada sebelum menghapus.
2. **Soft Delete (opsional)**: Jika ingin pakai soft delete, ganti `delete()` dengan `update(['deleted_at' => date('Y-m-d H:i:s')])`.
3. **Authorization**: Tambahkan middleware/filter untuk cek token/auth jika diperlukan.
4. **Logging**: Pertimbangkan log audit untuk tracking penghapusan.
5. **Transaction**: Gunakan DB transaction jika menghapus data berelasi (cascade).

## Testing dengan curl

```bash
curl -X POST http://192.168.78.2:8080/api/sync/deletions \
  -H "Content-Type: application/json" \
  -d '{
    "deletions": [
      {
        "entity_type": "barang",
        "server_id": 1,
        "kode": "BRG-001",
        "nama": "Barang Test",
        "deleted_at": "2026-01-12T10:00:00Z"
      }
    ]
  }'
```

## Testing dengan PowerShell

```powershell
$body = @{
  deletions = @(
    @{
      entity_type = "barang"
      server_id = 1
      kode = "BRG-001"
      nama = "Barang Test"
      deleted_at = "2026-01-12T10:00:00Z"
    }
  )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method POST `
  -Uri "http://192.168.78.2:8080/api/sync/deletions" `
  -Headers @{ 'Content-Type' = 'application/json' } `
  -Body $body
```
