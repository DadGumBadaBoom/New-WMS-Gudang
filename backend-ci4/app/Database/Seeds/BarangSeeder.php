<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class BarangSeeder extends Seeder
{
    // Seed data awal barang untuk uji coba
    public function run()
    {
        $data = [
            [
                'kode_barang'   => 'BRG-001',
                'nama_barang'   => 'Kardus Besar',
                'kategori'      => 'Packaging',
                'satuan'        => 'pcs',
                'harga'         => 15000,
                'stok_minimum'  => 10,
                'stok_saat_ini' => 50,
            ],
            [
                'kode_barang'   => 'BRG-002',
                'nama_barang'   => 'Plastik Bubble',
                'kategori'      => 'Packaging',
                'satuan'        => 'roll',
                'harga'         => 25000,
                'stok_minimum'  => 5,
                'stok_saat_ini' => 20,
            ],
            [
                'kode_barang'   => 'BRG-003',
                'nama_barang'   => 'Lakban Coklat',
                'kategori'      => 'Packaging',
                'satuan'        => 'roll',
                'harga'         => 8000,
                'stok_minimum'  => 15,
                'stok_saat_ini' => 40,
            ],
        ];

        $this->db->table('barang')->insertBatch($data);
    }
}
