<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class ApiTokenFilter implements FilterInterface
{
    // Memvalidasi header Authorization: Bearer <token>
    public function before(RequestInterface $request, $arguments = null)
    {
        $header = $request->getHeaderLine('Authorization');
        $expected = env('api.token');

        if (!$expected) {
            return service('response')->setJSON([
                'status'  => 'error',
                'message' => 'API token belum dikonfigurasi',
            ])->setStatusCode(500);
        }

        if (strpos($header, 'Bearer ') !== 0) {
            return service('response')->setJSON([
                'status'  => 'error',
                'message' => 'Token tidak ditemukan',
            ])->setStatusCode(401);
        }

        $token = trim(substr($header, 7));
        if ($token !== $expected) {
            return service('response')->setJSON([
                'status'  => 'error',
                'message' => 'Token tidak valid',
            ])->setStatusCode(401);
        }
    }

    // Tidak ada aksi khusus setelah request
    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
    }
}
