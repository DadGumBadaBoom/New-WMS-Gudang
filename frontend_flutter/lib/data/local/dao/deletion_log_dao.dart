import 'package:sqflite/sqflite.dart';

import '../db_provider.dart';
import '../models/deletion_log_local.dart';

class DeletionLogDao {
  Future<Database> get _db async => DbProvider.instance.database;

  Future<int> insert(DeletionLogLocal log) async {
    final db = await _db;
    return db.insert('deletion_log', log.toMap());
  }

  Future<List<DeletionLogLocal>> getRecent({int limit = 100}) async {
    final db = await _db;
    final res = await db.query(
      'deletion_log',
      orderBy: 'deleted_at DESC',
      limit: limit,
    );
    return res.map((e) => DeletionLogLocal.fromMap(e)).toList();
  }

  Future<void> purgeOlderThan(int days) async {
    final db = await _db;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    await db.delete(
      'deletion_log',
      where: 'deleted_at < ?',
      whereArgs: [cutoff],
    );
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('deletion_log');
  }
}
