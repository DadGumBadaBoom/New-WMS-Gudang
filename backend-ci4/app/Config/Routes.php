<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

// Grup API REST dengan proteksi token
$routes->group('api', ['filter' => 'apitoken'], static function ($routes) {
	// Resource utama WMS
	$routes->resource('barang', ['controller' => 'Api\BarangController']);
	$routes->resource('stok', ['controller' => 'Api\StokController']);
	$routes->resource('transaksi-masuk', ['controller' => 'Api\TransaksiMasukController']);
	$routes->resource('transaksi-keluar', ['controller' => 'Api\TransaksiKeluarController']);

	// Endpoint sinkronisasi
	$routes->post('sync/push', 'Api\SyncController::push');
	$routes->get('sync/pull', 'Api\SyncController::pull');
	$routes->post('sync/batch', 'Api\SyncController::batch');

	// Health check sederhana
	$routes->get('health', 'Api\HealthController::index');
});
