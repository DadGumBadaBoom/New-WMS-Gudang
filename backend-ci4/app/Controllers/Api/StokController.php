<?php

namespace App\Controllers\Api;

use App\Models\BarangModel;
use App\Models\StokModel;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\RESTful\ResourceController;

class StokController extends ResourceController
{
    use ResponseTrait;

    protected $modelName = StokModel::class;
    protected $format    = 'json';

    protected BarangModel $barangModel;

    public function __construct()
    {
        $this->barangModel = new BarangModel();
    }

    // Ambil stok dengan filter barang_id + paginasi
    public function index()
    {
        $barangId = $this->request->getGet('barang_id');
        $perPage  = (int) ($this->request->getGet('per_page') ?? 20);
        $page     = (int) ($this->request->getGet('page') ?? 1);

        if ($barangId) {
            $this->model->where('barang_id', $barangId);
        }

        $data  = $this->model->orderBy('id', 'DESC')->paginate($perPage, 'default', $page);
        $pager = $this->model->pager->getDetails();

        return $this->respond([
            'data'  => $data,
            'pager' => $pager,
        ]);
    }

    // Detail stok per id
    public function show($id = null)
    {
        $stok = $this->model->find($id);
        if (!$stok) {
            return $this->failNotFound('Stok tidak ditemukan');
        }
        return $this->respond($stok);
    }

    // Tambah stok agregat (sinkron dengan master barang)
    public function create()
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getPost();
        $barang  = $this->barangModel->find($payload['barang_id'] ?? null);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }
        if (!$this->model->insert($payload)) {
            return $this->failValidationErrors($this->model->errors());
        }
        // Update stok di master barang agar konsisten
        $this->barangModel->update($barang['id'], [
            'stok_saat_ini' => $payload['jumlah'] ?? 0,
        ]);
        $id = $this->model->getInsertID();
        return $this->respondCreated($this->model->find($id));
    }

    // Ubah stok agregat dan sinkron dengan master barang
    public function update($id = null)
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getRawInput();
        $stok    = $this->model->find($id);
        if (!$stok) {
            return $this->failNotFound('Stok tidak ditemukan');
        }
        $barang = $this->barangModel->find($payload['barang_id'] ?? $stok['barang_id']);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }
        if (!$this->model->update($id, $payload)) {
            return $this->failValidationErrors($this->model->errors());
        }
        $jumlahBaru = $payload['jumlah'] ?? $stok['jumlah'];
        $this->barangModel->update($barang['id'], ['stok_saat_ini' => $jumlahBaru]);
        return $this->respond($this->model->find($id));
    }

    // Hapus stok
    public function delete($id = null)
    {
        $stok = $this->model->find($id);
        if (!$stok) {
            return $this->failNotFound('Stok tidak ditemukan');
        }
        $this->model->delete($id);
        return $this->respondDeleted(['message' => 'Stok dihapus']);
    }
}
