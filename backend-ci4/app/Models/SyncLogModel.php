<?php

namespace App\Models;

use CodeIgniter\Model;

class SyncLogModel extends Model
{
    // Model untuk tabel log sinkronisasi
    protected $table            = 'sync_log';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $allowedFields    = [
        'device_id',
        'table_name',
        'record_id',
        'action',
        'sync_at',
        'created_at',
        'updated_at',
    ];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $validationRules = [
        'device_id'  => 'required',
        'table_name' => 'required',
        'record_id'  => 'required|integer',
        'action'     => 'required|in_list[create,update,delete]',
    ];
}
