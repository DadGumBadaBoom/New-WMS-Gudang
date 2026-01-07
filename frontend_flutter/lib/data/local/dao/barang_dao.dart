import 'package:sqflite/sqflite.dart';

import '../db_provider.dart';
import '../models/barang_local.dart';

// DAO untuk operasi barang lokal
class BarangDao {
  Future<Database> get _db async => DbProvider.instance.database;

  Future<int> insertBarang(BarangLocal barang) async {
    final db = await _db;
    return db.insert('barang_local', barang.toMap());
  }

  Future<List<BarangLocal>> getAll({String? keyword}) async {
    final db = await _db;
    final whereClause = keyword != null && keyword.isNotEmpty
        ? 'WHERE nama_barang LIKE ? OR kode_barang LIKE ?'
        : '';
    final args = keyword != null && keyword.isNotEmpty
        ? ['%$keyword%', '%$keyword%']
        : [];
    final res = await db.rawQuery(
      'SELECT * FROM barang_local $whereClause ORDER BY nama_barang ASC',
      args,
    );
    return res.map((e) => BarangLocal.fromMap(e)).toList();
  }

  Future<int> updateBarang(BarangLocal barang) async {
    final db = await _db;
    return db.update(
      'barang_local',
      barang.toMap(),
      where: 'id = ?',
      whereArgs: [barang.id],
    );
  }

  Future<int> deleteBarang(int id) async {
    final db = await _db;
    return db.delete('barang_local', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteById(int id) async {
    final db = await _db;
    return db.delete('barang_local', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('barang_local');
  }

  Future<void> clearPending() async {
    final db = await _db;
    await db.delete('barang_local', where: 'is_synced = 0');
  }

  Future<void> resetSyncStatus() async {
    final db = await _db;
    await db.update('barang_local', {'is_synced': 0});
  }

  Future<List<BarangLocal>> getPendingSync() async {
    final db = await _db;
    final res = await db.query('barang_local', where: 'is_synced = 0');
    return res.map((e) => BarangLocal.fromMap(e)).toList();
  }

  Future<BarangLocal?> getByServerId(int serverId) async {
    final db = await _db;
    final res = await db.query(
      'barang_local',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return BarangLocal.fromMap(res.first);
  }

  Future<BarangLocal?> getByKodeBarang(String kode) async {
    final db = await _db;
    final res = await db.query(
      'barang_local',
      where: 'kode_barang = ?',
      whereArgs: [kode],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return BarangLocal.fromMap(res.first);
  }

  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _db;
    await db.update(
      'barang_local',
      {'is_synced': 1, if (serverId != null) 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
