<?php

namespace App\Models;

use CodeIgniter\Model;

class BarangModel extends Model
{
    // Model untuk tabel master barang
    protected $table            = 'barang';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = true;
    protected $allowedFields    = [
        'kode_barang',
        'nama_barang',
        'kategori',
        'satuan',
        'harga',
        'stok_minimum',
        'stok_saat_ini',
        'created_at',
        'updated_at',
        'deleted_at',
    ];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';
    protected $deletedField  = 'deleted_at';

    // Validasi sederhana untuk input barang
    protected $validationRules = [
        'kode_barang' => 'required|min_length[3]|max_length[50]',
        'nama_barang' => 'required|min_length[3]|max_length[150]',
        'satuan'      => 'required|max_length[50]',
        'harga'       => 'permit_empty|decimal',
    ];
}
