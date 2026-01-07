<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateSyncLogTable extends Migration
{
    // Mencatat riwayat sinkronisasi antar perangkat dan server
    public function up(): void
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'device_id' => [
                'type'       => 'VARCHAR',
                'constraint' => 100,
            ],
            'table_name' => [
                'type'       => 'VARCHAR',
                'constraint' => 100,
            ],
            'record_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'action' => [
                'type'       => 'ENUM',
                'constraint' => ['create', 'update', 'delete'],
            ],
            'sync_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey(['device_id', 'table_name']);
        $this->forge->createTable('sync_log', true);
    }

    // Menghapus tabel log sinkronisasi
    public function down(): void
    {
        $this->forge->dropTable('sync_log', true);
    }
}
