<?php

namespace App\Controllers\Api;

use App\Models\BarangModel;
use App\Models\StokModel;
use App\Models\SyncLogModel;
use App\Models\TransaksiKeluarModel;
use App\Models\TransaksiMasukModel;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\RESTful\ResourceController;
use Config\Database;
use Throwable;

class SyncController extends ResourceController
{
    use ResponseTrait;

    protected BarangModel $barangModel;
    protected StokModel $stokModel;
    protected TransaksiMasukModel $trxMasukModel;
    protected TransaksiKeluarModel $trxKeluarModel;
    protected SyncLogModel $syncLogModel;

    public function __construct()
    {
        $this->barangModel    = new BarangModel();
        $this->stokModel      = new StokModel();
        $this->trxMasukModel  = new TransaksiMasukModel();
        $this->trxKeluarModel = new TransaksiKeluarModel();
        $this->syncLogModel   = new SyncLogModel();
    }

    // Push data lokal ke server (upsert sederhana)
    public function push()
    {
        $payload  = $this->request->getJSON(true) ?? [];
        $deviceId = $payload['device_id'] ?? 'unknown';

        $db = Database::connect();
        $db->transStart();
        try {
            $barangSaved = $this->upsertList($this->barangModel, $payload['barang'] ?? [], $deviceId, 'barang');
            $stokSaved   = $this->upsertList($this->stokModel, $payload['stok'] ?? [], $deviceId, 'stok');
            $masukSaved  = $this->upsertList($this->trxMasukModel, $payload['transaksi_masuk'] ?? [], $deviceId, 'transaksi_masuk');
            $keluarSaved = $this->upsertList($this->trxKeluarModel, $payload['transaksi_keluar'] ?? [], $deviceId, 'transaksi_keluar');
        } catch (Throwable $e) {
            $db->transRollback();
            return $this->failValidationErrors($e->getMessage());
        }

        $db->transComplete();
        if (!$db->transStatus()) {
            return $this->failServerError('Gagal push data');
        }

        return $this->respond([
            'status'           => 'ok',
            'barang_disimpan'  => $barangSaved,
            'stok_disimpan'    => $stokSaved,
            'masuk_disimpan'   => $masukSaved,
            'keluar_disimpan'  => $keluarSaved,
        ]);
    }

    // Pull data terbaru dari server
    public function pull()
    {
        $updatedAfter = $this->request->getGet('updated_after');
        $perPage      = (int) ($this->request->getGet('per_page') ?? 200); // batasi payload
        $page         = (int) ($this->request->getGet('page') ?? 1);

        $barang = $this->fetchData($this->barangModel, $updatedAfter, $perPage, $page);
        $stok   = $this->fetchData($this->stokModel, $updatedAfter, $perPage, $page);
        $masuk  = $this->fetchData($this->trxMasukModel, $updatedAfter, $perPage, $page);
        $keluar = $this->fetchData($this->trxKeluarModel, $updatedAfter, $perPage, $page);

        return $this->respond([
            'status'            => 'ok',
            'barang'            => $barang['data'],
            'barang_pager'      => $barang['pager'],
            'stok'              => $stok['data'],
            'stok_pager'        => $stok['pager'],
            'transaksi_masuk'   => $masuk['data'],
            'transaksi_masuk_pager' => $masuk['pager'],
            'transaksi_keluar'  => $keluar['data'],
            'transaksi_keluar_pager' => $keluar['pager'],
        ]);
    }

    // Batch push + pull dalam satu request
    public function batch()
    {
        $pushResult = $this->push();
        // Jika push mengembalikan ResponseInterface, langsung return
        if (method_exists($pushResult, 'getStatusCode') && $pushResult->getStatusCode() >= 400) {
            return $pushResult;
        }
        // Setelah push, lakukan pull
        return $this->pull();
    }

    // Helper untuk upsert list dan mencatat log sync
    protected function upsertList($model, array $rows, string $deviceId, string $tableName): array
    {
        $savedIds = [];
        foreach ($rows as $row) {
            if (!$model->save($row)) {
                $errors = $model->errors();
                $encoded = $errors ? json_encode($errors) : 'Validasi gagal';
                throw new \RuntimeException($encoded);
            }
            $recordId = $row[$model->primaryKey] ?? $model->getInsertID();
            $savedIds[] = $recordId;
            $this->syncLogModel->insert([
                'device_id'  => $deviceId,
                'table_name' => $tableName,
                'record_id'  => $recordId ?? 0,
                'action'     => 'update',
                'sync_at'    => date('Y-m-d H:i:s'),
            ]);
        }
        return $savedIds;
    }

    // Helper tarik data dengan filter waktu + paginasi
    protected function fetchData($model, ?string $updatedAfter, int $perPage, int $page): array
    {
        if ($updatedAfter) {
            $model->where('updated_at >', $updatedAfter);
        }
        $data  = $model->orderBy('updated_at', 'ASC')->paginate($perPage, 'default', $page);
        $pager = $model->pager->getDetails();

        return [
            'data'  => $data,
            'pager' => $pager,
        ];
    }
}
