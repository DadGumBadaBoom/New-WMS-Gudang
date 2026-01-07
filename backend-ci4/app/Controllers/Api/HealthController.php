<?php

namespace App\Controllers\Api;

use App\Models\SyncLogModel;
use CodeIgniter\API\ResponseTrait;
use CodeIgniter\Controller;
use Config\Database;

class HealthController extends Controller
{
    use ResponseTrait;

    protected SyncLogModel $syncLogModel;

    public function __construct()
    {
        $this->syncLogModel = new SyncLogModel();
    }

    public function index()
    {
        $dbStatus = 'ok';
        try {
            $db = Database::connect();
            $db->reconnect();
        } catch (\Throwable $e) {
            $dbStatus = 'error';
        }

        $lastSync = $this->syncLogModel
            ->orderBy('sync_at', 'DESC')
            ->select('device_id, table_name, record_id, action, sync_at')
            ->first();

        return $this->respond([
            'status'    => 'ok',
            'db'        => $dbStatus,
            'time'      => date('c'),
            'last_sync' => $lastSync,
        ]);
    }
}
