<?php

namespace App\Controllers\Api;

use App\Models\BarangModel;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\RESTful\ResourceController;

class BarangController extends ResourceController
{
    use ResponseTrait;

    protected $modelName = BarangModel::class;
    protected $format    = 'json';

    // Ambil barang dengan pencarian & paginasi ringan
    public function index()
    {
        $keyword = $this->request->getGet('q');
        $perPage = (int) ($this->request->getGet('per_page') ?? 20);
        $page    = (int) ($this->request->getGet('page') ?? 1);

        if ($keyword) {
            $this->model
                ->groupStart()
                ->like('kode_barang', $keyword)
                ->orLike('nama_barang', $keyword)
                ->groupEnd();
        }

        $data   = $this->model->orderBy('nama_barang', 'ASC')->paginate($perPage, 'default', $page);
        $pager  = $this->model->pager->getDetails();

        return $this->respond([
            'data'  => $data,
            'pager' => $pager,
        ]);
    }

    // Detail barang
    public function show($id = null)
    {
        $barang = $this->model->find($id);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }
        return $this->respond($barang);
    }

    // Tambah barang baru
    public function create()
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getPost();
        if (!$this->model->insert($payload)) {
            return $this->failValidationErrors($this->model->errors());
        }
        $id = $this->model->getInsertID();
        return $this->respondCreated($this->model->find($id));
    }

    // Ubah data barang
    public function update($id = null)
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getRawInput();
        $barang  = $this->model->find($id);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }
        if (!$this->model->update($id, $payload)) {
            return $this->failValidationErrors($this->model->errors());
        }
        return $this->respond($this->model->find($id));
    }

    // Hapus barang (soft delete)
    public function delete($id = null)
    {
        $barang = $this->model->find($id);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }
        $this->model->delete($id);
        return $this->respondDeleted(['message' => 'Barang dihapus']);
    }
}
