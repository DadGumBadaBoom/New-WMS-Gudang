import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/dao/barang_dao.dart';
import '../local/dao/stok_dao.dart';
import '../local/dao/transaksi_keluar_dao.dart';
import '../local/dao/transaksi_masuk_dao.dart';
import '../local/models/barang_local.dart';
import '../local/models/stok_local.dart';
import '../local/models/transaksi_keluar_local.dart';
import '../local/models/transaksi_masuk_local.dart';
import '../remote/api_service.dart';

// Repository sinkronisasi sederhana (push-pull) dengan strategi server wins
class SyncRepository {
  SyncRepository({
    ApiService? apiService,
    BarangDao? barangDao,
    StokDao? stokDao,
    TransaksiMasukDao? transaksiMasukDao,
    TransaksiKeluarDao? transaksiKeluarDao,
  }) : _api = apiService ?? ApiService(),
       _barangDao = barangDao ?? BarangDao(),
       _stokDao = stokDao ?? StokDao(),
       _transaksiMasukDao = transaksiMasukDao ?? TransaksiMasukDao(),
       _transaksiKeluarDao = transaksiKeluarDao ?? TransaksiKeluarDao();

  final ApiService _api;
  final BarangDao _barangDao;
  final StokDao _stokDao;
  final TransaksiMasukDao _transaksiMasukDao;
  final TransaksiKeluarDao _transaksiKeluarDao;

  static const _kLastPushKey = 'last_push_at';
  static const _kLastPullKey = 'last_pull_at';

  // Push data lokal yang belum sinkron
  Future<void> pushPending(String deviceId) async {
    final pendingBarang = await _barangDao.getPendingSync();
    final pendingStok = await _stokDao.getPendingSync();
    final pendingMasuk = await _transaksiMasukDao.getPendingSync();
    final pendingKeluar = await _transaksiKeluarDao.getPendingSync();

    if (pendingBarang.isEmpty &&
        pendingStok.isEmpty &&
        pendingMasuk.isEmpty &&
        pendingKeluar.isEmpty) {
      return;
    }

    final payload = {
      'device_id': deviceId,
      'barang': pendingBarang.map((b) => _mapBarangForPush(b)).toList(),
      'stok': pendingStok.map((s) => _mapStokForPush(s)).toList(),
      'transaksi_masuk': pendingMasuk.map((m) => _mapMasukForPush(m)).toList(),
      'transaksi_keluar': pendingKeluar
          .map((k) => _mapKeluarForPush(k))
          .toList(),
    };

    final Response response = await _api.syncPush(payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final barangIds = (data['barang_disimpan'] as List?) ?? [];
      final stokIds = (data['stok_disimpan'] as List?) ?? [];
      final masukIds = (data['masuk_disimpan'] as List?) ?? [];
      final keluarIds = (data['keluar_disimpan'] as List?) ?? [];

      for (var i = 0; i < pendingBarang.length; i++) {
        final serverId = i < barangIds.length ? _asInt(barangIds[i]) : null;
        await _barangDao.markSynced(pendingBarang[i].id!, serverId: serverId);
      }
      for (var i = 0; i < pendingStok.length; i++) {
        final serverId = i < stokIds.length ? _asInt(stokIds[i]) : null;
        await _stokDao.markSynced(pendingStok[i].id!, serverId: serverId);
      }
      for (var i = 0; i < pendingMasuk.length; i++) {
        final serverId = i < masukIds.length ? _asInt(masukIds[i]) : null;
        await _transaksiMasukDao.markSynced(
          pendingMasuk[i].id!,
          serverId: serverId,
        );
      }
      for (var i = 0; i < pendingKeluar.length; i++) {
        final serverId = i < keluarIds.length ? _asInt(keluarIds[i]) : null;
        await _transaksiKeluarDao.markSynced(
          pendingKeluar[i].id!,
          serverId: serverId,
        );
      }

      await _touchLastPush();
    }
  }

  // Pull data terbaru dari server (incremental)
  Future<void> pullUpdates({String? updatedAfter}) async {
    final Response response = await _api.syncPull(updatedAfter: updatedAfter);
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final List barang = data['barang'] ?? [];
      final List stok = data['stok'] ?? [];
      final List masuk = data['transaksi_masuk'] ?? [];
      final List keluar = data['transaksi_keluar'] ?? [];
      for (final row in barang) {
        final mapped = BarangLocal(
          serverId: _asInt(row['id']),
          kodeBarang: row['kode_barang'] ?? '',
          namaBarang: row['nama_barang'] ?? '',
          kategori: row['kategori'],
          satuan: row['satuan'] ?? '',
          harga: _asDouble(row['harga']),
          stokMinimum: _asInt(row['stok_minimum']),
          stokSaatIni: _asInt(row['stok_saat_ini']),
          lastModified: row['updated_at'] ?? '',
          isSynced: 1,
        );
        // Upsert sederhana berdasarkan server_id + kode
        await _upsertBarang(mapped);
      }
      for (final row in stok) {
        final mapped = StokLocal(
          serverId: _asInt(row['id']),
          barangServerId: _asInt(row['barang_id']),
          jumlah: _asInt(row['jumlah']),
          keterangan: row['keterangan'],
          lastModified: row['updated_at'] ?? '',
          isSynced: 1,
        );
        await _upsertStok(mapped);
      }
      for (final row in masuk) {
        final mapped = TransaksiMasukLocal(
          serverId: _asInt(row['id']),
          kodeTransaksi: row['kode_transaksi'] ?? '',
          tanggal: row['tanggal'] ?? '',
          supplier: row['supplier'],
          barangServerId: _asInt(row['barang_id']),
          jumlah: _asInt(row['jumlah']),
          hargaBeli: _asDouble(row['harga_beli']),
          keterangan: row['keterangan'],
          lastModified: row['updated_at'] ?? '',
          isSynced: 1,
        );
        await _upsertMasuk(mapped);
      }
      for (final row in keluar) {
        final mapped = TransaksiKeluarLocal(
          serverId: _asInt(row['id']),
          kodeTransaksi: row['kode_transaksi'] ?? '',
          tanggal: row['tanggal'] ?? '',
          tujuan: row['tujuan'],
          barangServerId: _asInt(row['barang_id']),
          jumlah: _asInt(row['jumlah']),
          keterangan: row['keterangan'],
          lastModified: row['updated_at'] ?? '',
          isSynced: 1,
        );
        await _upsertKeluar(mapped);
      }

      await _dedupeBarangLocal();

      await _touchLastPull();
    }
  }

  Map<String, dynamic> _mapBarangForPush(BarangLocal b) {
    return {
      if (b.serverId != null) 'id': b.serverId,
      'kode_barang': b.kodeBarang,
      'nama_barang': b.namaBarang,
      'kategori': b.kategori,
      'satuan': b.satuan,
      'harga': b.harga,
      'stok_minimum': b.stokMinimum,
      'stok_saat_ini': b.stokSaatIni,
      'updated_at': b.lastModified,
    };
  }

  Map<String, dynamic> _mapStokForPush(StokLocal s) {
    return {
      if (s.serverId != null) 'id': s.serverId,
      'barang_id': s.barangServerId,
      'jumlah': s.jumlah,
      'keterangan': s.keterangan,
      'updated_at': s.lastModified,
    };
  }

  Map<String, dynamic> _mapMasukForPush(TransaksiMasukLocal m) {
    return {
      if (m.serverId != null) 'id': m.serverId,
      'kode_transaksi': m.kodeTransaksi,
      'tanggal': m.tanggal,
      'supplier': m.supplier,
      'barang_id': m.barangServerId,
      'jumlah': m.jumlah,
      'harga_beli': m.hargaBeli,
      'keterangan': m.keterangan,
      'updated_at': m.lastModified,
    };
  }

  Map<String, dynamic> _mapKeluarForPush(TransaksiKeluarLocal k) {
    return {
      if (k.serverId != null) 'id': k.serverId,
      'kode_transaksi': k.kodeTransaksi,
      'tanggal': k.tanggal,
      'tujuan': k.tujuan,
      'barang_id': k.barangServerId,
      'jumlah': k.jumlah,
      'keterangan': k.keterangan,
      'updated_at': k.lastModified,
    };
  }

  Future<void> _upsertBarang(BarangLocal barang) async {
    if (barang.serverId == null) return;

    final currentById = await _barangDao.getByServerId(barang.serverId!);
    final currentByKode = await _barangDao.getByKodeBarang(barang.kodeBarang);

    final target = currentById ?? currentByKode;

    if (target == null) {
      await _barangDao.insertBarang(barang);
    } else {
      await _barangDao.updateBarang(
        target.copyWith(
          serverId: barang.serverId,
          kodeBarang: barang.kodeBarang,
          namaBarang: barang.namaBarang,
          kategori: barang.kategori,
          satuan: barang.satuan,
          harga: barang.harga,
          stokMinimum: barang.stokMinimum,
          stokSaatIni: barang.stokSaatIni,
          lastModified: barang.lastModified,
          isSynced: 1,
        ),
      );
    }
  }

  Future<void> _dedupeBarangLocal() async {
    final all = await _barangDao.getAll();
    if (all.isEmpty) return;

    final Map<String, BarangLocal> keepMap = {};
    final List<int> deleteIds = [];

    for (final b in all) {
      final key = (b.serverId != null)
          ? 'id:${b.serverId}'
          : 'kode:${b.kodeBarang}';
      if (!keepMap.containsKey(key)) {
        keepMap[key] = b;
        continue;
      }
      final existing = keepMap[key]!;

      // Prefer record yang punya serverId, atau lastModified terbaru
      final existingScore =
          (existing.serverId != null ? 2 : 0) +
          (existing.lastModified.hashCode);
      final currentScore =
          (b.serverId != null ? 2 : 0) + (b.lastModified.hashCode);

      if (currentScore > existingScore) {
        keepMap[key] = b;
        deleteIds.add(existing.id ?? -1);
      } else {
        deleteIds.add(b.id ?? -1);
      }
    }

    for (final id in deleteIds.where((e) => e > 0)) {
      await _barangDao.deleteById(id);
    }
  }

  Future<void> _upsertStok(StokLocal stok) async {
    if (stok.serverId == null) return;
    final existing = await _stokDao.getByServerId(stok.serverId!);
    if (existing == null) {
      await _stokDao.insert(stok);
    } else {
      await _stokDao.update(
        existing.copyWith(
          barangServerId: stok.barangServerId,
          jumlah: stok.jumlah,
          keterangan: stok.keterangan,
          lastModified: stok.lastModified,
          isSynced: 1,
        ),
      );
    }
  }

  Future<void> _upsertMasuk(TransaksiMasukLocal trx) async {
    if (trx.serverId == null) return;
    final existing = await _transaksiMasukDao.getByServerId(trx.serverId!);
    if (existing == null) {
      await _transaksiMasukDao.insert(trx);
    } else {
      await _transaksiMasukDao.update(
        existing.copyWith(
          kodeTransaksi: trx.kodeTransaksi,
          tanggal: trx.tanggal,
          supplier: trx.supplier,
          barangServerId: trx.barangServerId,
          jumlah: trx.jumlah,
          hargaBeli: trx.hargaBeli,
          keterangan: trx.keterangan,
          lastModified: trx.lastModified,
          isSynced: 1,
        ),
      );
    }
  }

  Future<void> _upsertKeluar(TransaksiKeluarLocal trx) async {
    if (trx.serverId == null) return;
    final existing = await _transaksiKeluarDao.getByServerId(trx.serverId!);
    if (existing == null) {
      await _transaksiKeluarDao.insert(trx);
    } else {
      await _transaksiKeluarDao.update(
        existing.copyWith(
          kodeTransaksi: trx.kodeTransaksi,
          tanggal: trx.tanggal,
          tujuan: trx.tujuan,
          barangServerId: trx.barangServerId,
          jumlah: trx.jumlah,
          keterangan: trx.keterangan,
          lastModified: trx.lastModified,
          isSynced: 1,
        ),
      );
    }
  }

  // Helper konversi dinamis ke int
  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  // Helper konversi dinamis ke double
  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _touchLastPush() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastPushKey, DateTime.now().toIso8601String());
  }

  Future<void> _touchLastPull() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastPullKey, DateTime.now().toIso8601String());
  }

  Future<Map<String, DateTime?>> getLastSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pushRaw = prefs.getString(_kLastPushKey);
    final pullRaw = prefs.getString(_kLastPullKey);
    return {'push': _safeParseDate(pushRaw), 'pull': _safeParseDate(pullRaw)};
  }

  DateTime? _safeParseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<String> checkHealth() async {
    final res = await _api.healthCheck<Map<String, dynamic>>();
    if (res.statusCode == 200 && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final status = data['status'] ?? 'unknown';
      final db = data['db'] ?? 'unknown';
      final time = data['time'] ?? '';
      return 'Server: $status · DB: $db · $time';
    }
    return 'Server tidak merespons';
  }
}
