import 'package:sqflite/sqflite.dart';

import '../db_provider.dart';
import '../models/stok_local.dart';

class StokDao {
  Future<Database> get _db async => DbProvider.instance.database;

  Future<int> insert(StokLocal stok) async {
    final db = await _db;
    return db.insert('stok_local', stok.toMap());
  }

  Future<int> update(StokLocal stok) async {
    final db = await _db;
    return db.update(
      'stok_local',
      stok.toMap(),
      where: 'id = ?',
      whereArgs: [stok.id],
    );
  }

  Future<List<StokLocal>> getPendingSync() async {
    final db = await _db;
    final res = await db.query('stok_local', where: 'is_synced = 0');
    return res.map((e) => StokLocal.fromMap(e)).toList();
  }

  Future<StokLocal?> getByServerId(int serverId) async {
    final db = await _db;
    final res = await db.query(
      'stok_local',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return StokLocal.fromMap(res.first);
  }

  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _db;
    await db.update(
      'stok_local',
      {'is_synced': 1, if (serverId != null) 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('stok_local');
  }

  Future<void> clearPending() async {
    final db = await _db;
    await db.delete('stok_local', where: 'is_synced = 0');
  }

  Future<void> resetSyncStatus() async {
    final db = await _db;
    await db.update('stok_local', {'is_synced': 0});
  }
}
