<?php

namespace App\Models;

use CodeIgniter\Model;

class TransaksiKeluarModel extends Model
{
    // Model untuk tabel transaksi barang keluar
    protected $table            = 'transaksi_keluar';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $allowedFields    = [
        'kode_transaksi',
        'tanggal',
        'tujuan',
        'barang_id',
        'jumlah',
        'keterangan',
        'created_at',
        'updated_at',
    ];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $validationRules = [
        'kode_transaksi' => 'required|max_length[50]',
        'tanggal'        => 'required|valid_date[Y-m-d]|regex_match[/^\d{4}-\d{2}-\d{2}$/]',
        'barang_id'      => 'required|integer',
        'jumlah'         => 'required|integer|greater_than[0]',
    ];
}
