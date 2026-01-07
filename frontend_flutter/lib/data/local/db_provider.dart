import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Provider DB SQLite untuk offline-first
class DbProvider {
  DbProvider._internal();
  static final DbProvider instance = DbProvider._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wms_local.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Tabel master barang lokal
        await db.execute('''
          CREATE TABLE barang_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            kode_barang TEXT,
            nama_barang TEXT,
            kategori TEXT,
            satuan TEXT,
            harga REAL,
            stok_minimum INTEGER,
            stok_saat_ini INTEGER,
            last_modified TEXT,
            is_synced INTEGER DEFAULT 0
          );
        ''');

        // Tabel stok agregat lokal
        await db.execute('''
          CREATE TABLE stok_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            barang_server_id INTEGER,
            jumlah INTEGER,
            keterangan TEXT,
            last_modified TEXT,
            is_synced INTEGER DEFAULT 0
          );
        ''');

        // Tabel transaksi masuk lokal
        await db.execute('''
          CREATE TABLE transaksi_masuk_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            kode_transaksi TEXT,
            tanggal TEXT,
            supplier TEXT,
            barang_server_id INTEGER,
            nama_barang TEXT,
            jumlah INTEGER,
            harga_beli REAL,
            keterangan TEXT,
            last_modified TEXT,
            is_synced INTEGER DEFAULT 0
          );
        ''');

        // Tabel transaksi keluar lokal
        await db.execute('''
          CREATE TABLE transaksi_keluar_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            kode_transaksi TEXT,
            tanggal TEXT,
            tujuan TEXT,
            barang_server_id INTEGER,
            nama_barang TEXT,
            jumlah INTEGER,
            keterangan TEXT,
            last_modified TEXT,
            is_synced INTEGER DEFAULT 0
          );
        ''');

        // Tabel riwayat hapus
        await db.execute('''
          CREATE TABLE deletion_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT,
            entity_id INTEGER,
            kode TEXT,
            nama TEXT,
            detail TEXT,
            deleted_at TEXT
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migration dari v1 ke v2: tambah column nama_barang
        if (oldVersion < 2) {
          try {
            await db.execute(
              'ALTER TABLE transaksi_masuk_local ADD COLUMN nama_barang TEXT',
            );
          } catch (_) {
            // Column sudah ada, skip
          }
          try {
            await db.execute(
              'ALTER TABLE transaksi_keluar_local ADD COLUMN nama_barang TEXT',
            );
          } catch (_) {
            // Column sudah ada, skip
          }
        }

        // Migration v2 -> v3: tabel deletion_log
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deletion_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity_type TEXT,
              entity_id INTEGER,
              kode TEXT,
              nama TEXT,
              detail TEXT,
              deleted_at TEXT
            );
          ''');
        }
      },
    );
  }
}
