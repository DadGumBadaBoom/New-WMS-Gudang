import 'package:sqflite/sqflite.dart';

import '../db_provider.dart';
import '../models/transaksi_keluar_local.dart';

class TransaksiKeluarDao {
  Future<Database> get _db async => DbProvider.instance.database;

  Future<int> insert(TransaksiKeluarLocal trx) async {
    final db = await _db;
    return db.insert('transaksi_keluar_local', trx.toMap());
  }

  Future<List<TransaksiKeluarLocal>> getAll() async {
    final db = await _db;
    final res = await db.query(
      'transaksi_keluar_local',
      orderBy: 'tanggal DESC, id DESC',
    );
    return res.map((e) => TransaksiKeluarLocal.fromMap(e)).toList();
  }

  Future<int> update(TransaksiKeluarLocal trx) async {
    final db = await _db;
    return db.update(
      'transaksi_keluar_local',
      trx.toMap(),
      where: 'id = ?',
      whereArgs: [trx.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete(
      'transaksi_keluar_local',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransaksiKeluarLocal>> getPendingSync() async {
    final db = await _db;
    final res = await db.query(
      'transaksi_keluar_local',
      where: 'is_synced = 0',
    );
    return res.map((e) => TransaksiKeluarLocal.fromMap(e)).toList();
  }

  Future<TransaksiKeluarLocal?> getByServerId(int serverId) async {
    final db = await _db;
    final res = await db.query(
      'transaksi_keluar_local',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return TransaksiKeluarLocal.fromMap(res.first);
  }

  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _db;
    await db.update(
      'transaksi_keluar_local',
      {'is_synced': 1, if (serverId != null) 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('transaksi_keluar_local');
  }

  Future<void> clearPending() async {
    final db = await _db;
    await db.delete('transaksi_keluar_local', where: 'is_synced = 0');
  }

  Future<void> resetSyncStatus() async {
    final db = await _db;
    await db.update('transaksi_keluar_local', {'is_synced': 0});
  }
}
