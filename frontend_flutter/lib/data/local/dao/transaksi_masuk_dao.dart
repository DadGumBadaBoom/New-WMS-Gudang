import 'package:sqflite/sqflite.dart';

import '../db_provider.dart';
import '../models/transaksi_masuk_local.dart';

class TransaksiMasukDao {
  Future<Database> get _db async => DbProvider.instance.database;

  Future<int> insert(TransaksiMasukLocal trx) async {
    final db = await _db;
    return db.insert('transaksi_masuk_local', trx.toMap());
  }

  Future<List<TransaksiMasukLocal>> getAll() async {
    final db = await _db;
    final res = await db.query(
      'transaksi_masuk_local',
      orderBy: 'tanggal DESC, id DESC',
    );
    return res.map((e) => TransaksiMasukLocal.fromMap(e)).toList();
  }

  Future<int> update(TransaksiMasukLocal trx) async {
    final db = await _db;
    return db.update(
      'transaksi_masuk_local',
      trx.toMap(),
      where: 'id = ?',
      whereArgs: [trx.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('transaksi_masuk_local', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransaksiMasukLocal>> getPendingSync() async {
    final db = await _db;
    final res = await db.query('transaksi_masuk_local', where: 'is_synced = 0');
    return res.map((e) => TransaksiMasukLocal.fromMap(e)).toList();
  }

  Future<TransaksiMasukLocal?> getByServerId(int serverId) async {
    final db = await _db;
    final res = await db.query(
      'transaksi_masuk_local',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return TransaksiMasukLocal.fromMap(res.first);
  }

  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _db;
    await db.update(
      'transaksi_masuk_local',
      {'is_synced': 1, if (serverId != null) 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('transaksi_masuk_local');
  }

  Future<void> clearPending() async {
    final db = await _db;
    await db.delete('transaksi_masuk_local', where: 'is_synced = 0');
  }

  Future<void> resetSyncStatus() async {
    final db = await _db;
    await db.update('transaksi_masuk_local', {'is_synced': 0});
  }
}
