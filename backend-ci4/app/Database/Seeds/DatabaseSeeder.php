<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    // Seeder utama memanggil seeder lain
    public function run()
    {
        $this->call(BarangSeeder::class);
    }
}
