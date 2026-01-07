<?php

namespace App\Controllers\Api;

use App\Models\BarangModel;
use App\Models\StokModel;
use App\Models\TransaksiMasukModel;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\RESTful\ResourceController;
use Config\Database;

class TransaksiMasukController extends ResourceController
{
    use ResponseTrait;

    protected $modelName = TransaksiMasukModel::class;
    protected $format    = 'json';

    protected BarangModel $barangModel;
    protected StokModel $stokModel;

    public function __construct()
    {
        $this->barangModel = new BarangModel();
        $this->stokModel   = new StokModel();
    }

    // List transaksi masuk dengan filter tanggal, barang, paginasi
    public function index()
    {
        $barangId   = $this->request->getGet('barang_id');
        $dateFrom   = $this->request->getGet('tanggal_from');
        $dateTo     = $this->request->getGet('tanggal_to');
        $keyword    = $this->request->getGet('q');
        $perPage    = (int) ($this->request->getGet('per_page') ?? 20);
        $page       = (int) ($this->request->getGet('page') ?? 1);

        if ($barangId) {
            $this->model->where('barang_id', $barangId);
        }
        if ($dateFrom) {
            $this->model->where('tanggal >=', $dateFrom);
        }
        if ($dateTo) {
            $this->model->where('tanggal <=', $dateTo);
        }
        if ($keyword) {
            $this->model->like('kode_transaksi', $keyword);
        }

        $data  = $this->model->orderBy('tanggal', 'DESC')->paginate($perPage, 'default', $page);
        $pager = $this->model->pager->getDetails();

        return $this->respond([
            'data'  => $data,
            'pager' => $pager,
        ]);
    }

    // Detail transaksi
    public function show($id = null)
    {
        $trx = $this->model->find($id);
        if (!$trx) {
            return $this->failNotFound('Transaksi masuk tidak ditemukan');
        }
        return $this->respond($trx);
    }

    // Tambah transaksi masuk dan tambah stok
    public function create()
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getPost();
        $barang  = $this->barangModel->find($payload['barang_id'] ?? null);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }

        $db = Database::connect();
        $db->transStart();

        if (!$this->model->insert($payload)) {
            $db->transRollback();
            return $this->failValidationErrors($this->model->errors());
        }

        $jumlah = (int) ($payload['jumlah'] ?? 0);
        $stokBaru = (int) $barang['stok_saat_ini'] + $jumlah;
        $this->barangModel->update($barang['id'], ['stok_saat_ini' => $stokBaru]);
        $this->upsertStokAgregat($barang['id'], $stokBaru);

        $db->transComplete();
        if (!$db->transStatus()) {
            return $this->failServerError('Gagal menyimpan transaksi');
        }

        $id = $this->model->getInsertID();
        return $this->respondCreated($this->model->find($id));
    }

    // Ubah transaksi masuk dan sesuaikan stok selisihnya
    public function update($id = null)
    {
        $payload = $this->request->getJSON(true) ?? $this->request->getRawInput();
        $trx     = $this->model->find($id);
        if (!$trx) {
            return $this->failNotFound('Transaksi masuk tidak ditemukan');
        }

        $barangId = $payload['barang_id'] ?? $trx['barang_id'];
        $barang   = $this->barangModel->find($barangId);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }

        $db = Database::connect();
        $db->transStart();

        if (!$this->model->update($id, $payload)) {
            $db->transRollback();
            return $this->failValidationErrors($this->model->errors());
        }

        $jumlahBaru    = (int) ($payload['jumlah'] ?? $trx['jumlah']);
        $selisih       = $jumlahBaru - (int) $trx['jumlah'];
        $stokBaru      = (int) $barang['stok_saat_ini'] + $selisih;
        $this->barangModel->update($barang['id'], ['stok_saat_ini' => $stokBaru]);
        $this->upsertStokAgregat($barang['id'], $stokBaru);

        $db->transComplete();
        if (!$db->transStatus()) {
            return $this->failServerError('Gagal memperbarui transaksi');
        }

        return $this->respond($this->model->find($id));
    }

    // Hapus transaksi masuk dan kurangi stok sesuai jumlah
    public function delete($id = null)
    {
        $trx = $this->model->find($id);
        if (!$trx) {
            return $this->failNotFound('Transaksi masuk tidak ditemukan');
        }

        $barang = $this->barangModel->find($trx['barang_id']);
        if (!$barang) {
            return $this->failNotFound('Barang tidak ditemukan');
        }

        $db = Database::connect();
        $db->transStart();

        $this->model->delete($id);
        $stokBaru = max(0, (int) $barang['stok_saat_ini'] - (int) $trx['jumlah']);
        $this->barangModel->update($barang['id'], ['stok_saat_ini' => $stokBaru]);
        $this->upsertStokAgregat($barang['id'], $stokBaru);

        $db->transComplete();
        if (!$db->transStatus()) {
            return $this->failServerError('Gagal menghapus transaksi');
        }

        return $this->respondDeleted(['message' => 'Transaksi masuk dihapus']);
    }

    // Membuat / memperbarui tabel stok agregat
    protected function upsertStokAgregat(int $barangId, int $jumlah): void
    {
        $stok = $this->stokModel->where('barang_id', $barangId)->first();
        if ($stok) {
            $this->stokModel->update($stok['id'], ['jumlah' => $jumlah]);
            return;
        }
        $this->stokModel->insert([
            'barang_id' => $barangId,
            'jumlah'    => $jumlah,
        ]);
    }
}
