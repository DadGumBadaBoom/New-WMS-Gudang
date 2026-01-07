<?php

namespace App\Models;

use CodeIgniter\Model;

class StokModel extends Model
{
    // Model untuk tabel stok agregat
    protected $table            = 'stok';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = true;
    protected $allowedFields    = [
        'barang_id',
        'jumlah',
        'keterangan',
        'created_at',
        'updated_at',
        'deleted_at',
    ];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';
    protected $deletedField  = 'deleted_at';

    // Validasi sederhana stok
    protected $validationRules = [
        'barang_id' => 'required|integer',
        'jumlah'    => 'required|integer|greater_than[0]',
    ];
}
