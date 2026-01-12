import 'package:flutter/material.dart';

import '../data/local/dao/barang_dao.dart';
import '../data/local/dao/deletion_log_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../data/local/dao/stok_dao.dart';
import '../data/local/dao/transaksi_keluar_dao.dart';
import '../data/local/dao/transaksi_masuk_dao.dart';
import '../data/local/models/barang_local.dart';
import '../data/local/models/deletion_log_local.dart';
import '../data/local/models/transaksi_keluar_local.dart';
import '../data/local/models/transaksi_masuk_local.dart';
import '../data/repository/sync_repository.dart';
import '../data/remote/api_service.dart';
import 'settings_page.dart';

// Halaman demo sederhana: daftar barang lokal + transaksi + tombol sinkronisasi
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _barangDao = BarangDao();
  final _deleteLogDao = DeletionLogDao();
  final _stokDao = StokDao();
  final _masukDao = TransaksiMasukDao();
  final _keluarDao = TransaksiKeluarDao();
  final _syncRepo = SyncRepository();

  late TabController _tabController;
  bool _loading = false;
  List<BarangLocal> _items = [];
  List<BarangLocal> _itemsFiltered = [];
  String _searchQuery = '';
  List<TransaksiMasukLocal> _itemsMasuk = [];
  List<TransaksiKeluarLocal> _itemsKeluar = [];
  List<DeletionLogLocal> _deleteLogs = [];
  String? _error;
  int _pendingCount = 0;
  int _pendingBarangCount = 0;
  int _pendingStokCount = 0;
  int _pendingMasukCount = 0;
  int _pendingKeluarCount = 0;
  DateTime? _lastPush;
  DateTime? _lastPull;
  String? _healthStatus;
  String? _lastRawError; // For troubleshooting
  List<Map<String, String>> _errorLogs =
      []; // Store error history with timestamp

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final data = await _barangDao.getAll();
    final masuk = await _masukDao.getAll();
    final keluar = await _keluarDao.getAll();
    await _deleteLogDao.purgeOlderThan(30);
    final deleteLogs = await _deleteLogDao.getRecent(limit: 100);

    final pendingBarang = await _barangDao.getPendingSync();
    final pendingStok = await _stokDao.getPendingSync();
    final pendingMasuk = await _masukDao.getPendingSync();
    final pendingKeluar = await _keluarDao.getPendingSync();
    setState(() {
      _items = data;
      _itemsFiltered = data;
      _itemsMasuk = masuk;
      _itemsKeluar = keluar;
      _deleteLogs = deleteLogs;
      _error = null;
      _pendingBarangCount = pendingBarang.length;
      _pendingStokCount = pendingStok.length;
      _pendingMasukCount = pendingMasuk.length;
      _pendingKeluarCount = pendingKeluar.length;
      _pendingCount =
          _pendingBarangCount +
          _pendingStokCount +
          _pendingMasukCount +
          _pendingKeluarCount;
    });
  }

  void _filterBarang(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _itemsFiltered = _items.where((b) {
        return b.namaBarang.toLowerCase().contains(_searchQuery) ||
            b.kodeBarang.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<String> _getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_name') ?? 'device-demo';
  }

  Future<SyncRepository> _makeSyncRepo() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('api_base_url');
    final api = ApiService(baseUrl: baseUrl);
    return SyncRepository(apiService: api);
  }

  Future<void> _logDeletion({
    required String entityType,
    int? entityId,
    int? serverId,
    required String kode,
    required String nama,
    String? detail,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _deleteLogDao.insert(
      DeletionLogLocal(
        entityType: entityType,
        entityId: entityId,
        serverId: serverId,
        kode: kode,
        nama: nama,
        detail: detail,
        deletedAt: now,
      ),
    );
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    try {
      final repo = await _makeSyncRepo();
      final device = await _getDeviceName();
      await repo.pushPending(device);
      await repo.pullUpdates();
      await _refresh();
      await _loadSyncStatus();
      setState(() => _lastRawError = null);
    } catch (e) {
      final rawMsg = e.toString();
      final timestamp = DateTime.now().toIso8601String();
      setState(() {
        _error = _formatErrorMessage(e);
        _lastRawError = rawMsg;
        _errorLogs.insert(0, {
          'timestamp': timestamp,
          'error': _formatErrorMessage(e),
          'raw': rawMsg,
        });
        // Keep only last 50 errors
        if (_errorLogs.length > 50) {
          _errorLogs.removeLast();
        }
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSyncStatus() async {
    final status = await _syncRepo.getLastSyncStatus();
    setState(() {
      _lastPush = status['push'];
      _lastPull = status['pull'];
    });
  }

  String? _validatePositiveInt(String? value, {String fieldLabel = 'Jumlah'}) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return '$fieldLabel harus angka';
    if (parsed <= 0) return '$fieldLabel harus > 0';
    return null;
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final trimmed = value.trim();
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(trimmed)) return 'Format YYYY-MM-DD';
    try {
      final parts = trimmed.split('-').map(int.parse).toList();
      final candidate = DateTime(parts[0], parts[1], parts[2]);
      if (candidate.year != parts[0] ||
          candidate.month != parts[1] ||
          candidate.day != parts[2]) {
        return 'Tanggal tidak valid';
      }
    } catch (_) {
      return 'Tanggal tidak valid';
    }
    return null;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  String _formatErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('connection') || msg.contains('refused')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet dan URL server.';
    }
    if (msg.contains('timeout')) {
      return 'Koneksi ke server timeout. Coba lagi nanti.';
    }
    if (msg.contains('route to host') || msg.contains('unreachable')) {
      return 'Server tidak dapat diakses. Periksa alamat IP server.';
    }
    if (msg.contains('socket')) {
      return 'Koneksi network error. Periksa koneksi internet Anda.';
    }
    if (msg.contains('unauthorized') || msg.contains('401')) {
      return 'Akses ditolak. Periksa token API di Settings.';
    }
    return 'Terjadi kesalahan. Coba lagi nanti.';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      controller.text = '$y-$m-$d';
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final parts = raw.split('-').map(int.parse).toList();
      if (parts.length == 3) return DateTime(parts[0], parts[1], parts[2]);
    } catch (_) {}
    return null;
  }

  Future<void> _editBarang(BarangLocal barang) async {
    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: barang.namaBarang);
    final satuanCtrl = TextEditingController(text: barang.satuan);
    final kategoriCtrl = TextEditingController(text: barang.kategori ?? '');
    final hargaCtrl = TextEditingController(text: barang.harga.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Barang'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: barang.kodeBarang,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Kode'),
                  ),
                  TextFormField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: satuanCtrl,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                  ),
                  TextFormField(
                    controller: kategoriCtrl,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  TextFormField(
                    controller: hargaCtrl,
                    decoration: const InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    initialValue: barang.stokSaatIni.toString(),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Stok Sekarang',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();
    final hargaValue = double.tryParse(hargaCtrl.text.trim()) ?? 0;

    await _barangDao.updateBarang(
      barang.copyWith(
        namaBarang: namaCtrl.text.trim(),
        satuan: satuanCtrl.text.trim(),
        kategori: kategoriCtrl.text.trim().isEmpty
            ? null
            : kategoriCtrl.text.trim(),
        harga: hargaValue,
        lastModified: now,
        isSynced: 0,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barang diperbarui')));
    }
    await _refresh();
  }

  Future<void> _deleteBarang(BarangLocal barang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: Text('Kode: ${barang.kodeBarang}\nNama: ${barang.namaBarang}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _logDeletion(
      entityType: 'barang',
      entityId: barang.id,
      serverId: barang.serverId,
      kode: barang.kodeBarang,
      nama: barang.namaBarang,
      detail: 'stok:${barang.stokSaatIni} synced:${barang.isSynced}',
    );
    await _barangDao.deleteBarang(barang.id ?? 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barang ${barang.namaBarang} dihapus')),
      );
    }
    await _refresh();
  }

  Future<void> _addBarang() async {
    final formKey = GlobalKey<FormState>();
    final kodeCtrl = TextEditingController(
      text: 'BRG-${DateTime.now().millisecondsSinceEpoch}',
    );
    final namaCtrl = TextEditingController(text: 'Barang Offline');
    final satuanCtrl = TextEditingController(text: 'pcs');
    final kategoriCtrl = TextEditingController(text: 'Demo');
    final hargaCtrl = TextEditingController(text: '5000');
    final stokCtrl = TextEditingController(text: '10');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Barang'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: kodeCtrl,
                    decoration: const InputDecoration(labelText: 'Kode'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: satuanCtrl,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                  ),
                  TextFormField(
                    controller: kategoriCtrl,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  TextFormField(
                    controller: hargaCtrl,
                    decoration: const InputDecoration(labelText: 'Harga'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: stokCtrl,
                    decoration: const InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        _validatePositiveInt(v, fieldLabel: 'Stok awal'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();
    final hargaValue = double.tryParse(hargaCtrl.text.trim()) ?? 0;
    await _barangDao.insertBarang(
      BarangLocal(
        kodeBarang: kodeCtrl.text.trim(),
        namaBarang: namaCtrl.text.trim(),
        kategori: kategoriCtrl.text.trim(),
        satuan: satuanCtrl.text.trim(),
        harga: hargaValue,
        stokMinimum: 0,
        stokSaatIni: int.parse(stokCtrl.text.trim()),
        lastModified: now,
      ),
    );
    await _refresh();
  }

  Future<void> _addTrxMasuk() async {
    final barangSynced = (await _barangDao.getAll())
        .where((b) => b.serverId != null)
        .toList();
    if (barangSynced.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sinkronkan barang dulu sebelum buat transaksi masuk',
            ),
          ),
        );
      }
      return;
    }

    final formKey = GlobalKey<FormState>();
    final kodeCtrl = TextEditingController(
      text: 'TRXIN-${DateTime.now().millisecondsSinceEpoch}',
    );
    final tglCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final supplierCtrl = TextEditingController(text: 'Supplier');
    final jumlahCtrl = TextEditingController(text: '1');
    final hargaCtrl = TextEditingController(text: '0');
    final ketCtrl = TextEditingController();
    BarangLocal? selected = barangSynced.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Transaksi Masuk'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<BarangLocal>(
                    isExpanded: true,
                    value: selected,
                    items: barangSynced
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              '${b.namaBarang} (${b.kodeBarang})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selected = v,
                    decoration: const InputDecoration(labelText: 'Barang'),
                  ),
                  TextFormField(
                    controller: kodeCtrl,
                    decoration: const InputDecoration(labelText: 'Kode'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: tglCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tanggal (YYYY-MM-DD)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(tglCtrl),
                      ),
                    ),
                    validator: _validateDate,
                  ),
                  TextFormField(
                    controller: supplierCtrl,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                  ),
                  TextFormField(
                    controller: jumlahCtrl,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        _validatePositiveInt(v, fieldLabel: 'Jumlah'),
                  ),
                  TextFormField(
                    controller: hargaCtrl,
                    decoration: const InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: ketCtrl,
                    decoration: const InputDecoration(labelText: 'Keterangan'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || selected == null) return;

    final now = DateTime.now().toIso8601String();
    final jumlahTambah = int.parse(jumlahCtrl.text.trim());
    await _masukDao.insert(
      TransaksiMasukLocal(
        kodeTransaksi: kodeCtrl.text.trim(),
        tanggal: tglCtrl.text.trim(),
        supplier: supplierCtrl.text.trim().isEmpty
            ? null
            : supplierCtrl.text.trim(),
        barangServerId: selected!.serverId,
        namaBarang: selected!.namaBarang,
        jumlah: jumlahTambah,
        hargaBeli: double.tryParse(hargaCtrl.text.trim()) ?? 0,
        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
        lastModified: now,
      ),
    );

    // Auto-update stok barang master
    await _barangDao.updateBarang(
      selected!.copyWith(
        stokSaatIni: selected!.stokSaatIni + jumlahTambah,
        lastModified: now,
        isSynced: 0,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi masuk +$jumlahTambah pcs dicatat'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await _refresh();
  }

  Future<void> _addTrxKeluar() async {
    final barangSynced = (await _barangDao.getAll())
        .where((b) => b.serverId != null)
        .toList();
    if (barangSynced.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sinkronkan barang dulu sebelum buat transaksi keluar',
            ),
          ),
        );
      }
      return;
    }

    final formKey = GlobalKey<FormState>();
    final kodeCtrl = TextEditingController(
      text: 'TRXOUT-${DateTime.now().millisecondsSinceEpoch}',
    );
    final tglCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final tujuanCtrl = TextEditingController(text: 'Tujuan');
    final jumlahCtrl = TextEditingController(text: '1');
    final ketCtrl = TextEditingController();
    BarangLocal? selected = barangSynced.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Transaksi Keluar'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<BarangLocal>(
                    isExpanded: true,
                    value: selected,
                    items: barangSynced
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              '${b.namaBarang} (${b.kodeBarang})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selected = v,
                    decoration: const InputDecoration(labelText: 'Barang'),
                  ),
                  TextFormField(
                    controller: kodeCtrl,
                    decoration: const InputDecoration(labelText: 'Kode'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: tglCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tanggal (YYYY-MM-DD)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _pickDate(tglCtrl),
                      ),
                    ),
                    validator: _validateDate,
                  ),
                  TextFormField(
                    controller: tujuanCtrl,
                    decoration: const InputDecoration(labelText: 'Tujuan'),
                  ),
                  TextFormField(
                    controller: jumlahCtrl,
                    decoration: const InputDecoration(labelText: 'Jumlah'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        _validatePositiveInt(v, fieldLabel: 'Jumlah'),
                  ),
                  TextFormField(
                    controller: ketCtrl,
                    decoration: const InputDecoration(labelText: 'Keterangan'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || selected == null) return;

    final now = DateTime.now().toIso8601String();
    final jumlahKurangi = int.parse(jumlahCtrl.text.trim());

    // Validasi stok cukup
    if (selected!.stokSaatIni < jumlahKurangi) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok tidak cukup (sekarang: ${selected!.stokSaatIni})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _keluarDao.insert(
      TransaksiKeluarLocal(
        kodeTransaksi: kodeCtrl.text.trim(),
        tanggal: tglCtrl.text.trim(),
        tujuan: tujuanCtrl.text.trim().isEmpty ? null : tujuanCtrl.text.trim(),
        barangServerId: selected!.serverId,
        namaBarang: selected!.namaBarang,
        jumlah: jumlahKurangi,
        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
        lastModified: now,
      ),
    );

    // Auto-update stok barang master
    await _barangDao.updateBarang(
      selected!.copyWith(
        stokSaatIni: selected!.stokSaatIni - jumlahKurangi,
        lastModified: now,
        isSynced: 0,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi keluar -$jumlahKurangi pcs dicatat'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    await _refresh();
  }

  void _openAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Tambah Barang'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _addBarang();
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_received),
                title: const Text('Transaksi Masuk'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _addTrxMasuk();
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_made),
                title: const Text('Transaksi Keluar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _addTrxKeluar();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editTrxMasuk(TransaksiMasukLocal trx) async {
    final formKey = GlobalKey<FormState>();
    final jumlahCtrl = TextEditingController(text: trx.jumlah.toString());
    final supplierCtrl = TextEditingController(text: trx.supplier ?? '');
    final hargaCtrl = TextEditingController(
      text: (trx.hargaBeli ?? 0).toString(),
    );
    final ketCtrl = TextEditingController(text: trx.keterangan ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Transaksi Masuk'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: trx.kodeTransaksi,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Kode'),
                ),
                TextFormField(
                  initialValue: trx.tanggal,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                ),
                TextFormField(
                  controller: supplierCtrl,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
                TextFormField(
                  controller: jumlahCtrl,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      _validatePositiveInt(v, fieldLabel: 'Jumlah'),
                ),
                TextFormField(
                  controller: hargaCtrl,
                  decoration: const InputDecoration(labelText: 'Harga Beli'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: ketCtrl,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();
    final newJumlah = int.parse(jumlahCtrl.text.trim());
    final oldJumlah = trx.jumlah;
    final selisih = newJumlah - oldJumlah;

    // Update transaksi
    await _masukDao.update(
      trx.copyWith(
        supplier: supplierCtrl.text.trim().isEmpty
            ? null
            : supplierCtrl.text.trim(),
        jumlah: newJumlah,
        hargaBeli: double.tryParse(hargaCtrl.text.trim()) ?? 0,
        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
        lastModified: now,
        isSynced: 0,
      ),
    );

    // Update stok barang jika jumlah berubah
    if (selisih != 0) {
      final barang = await _barangDao.getByServerId(trx.barangServerId ?? 0);
      if (barang != null) {
        await _barangDao.updateBarang(
          barang.copyWith(
            stokSaatIni: barang.stokSaatIni + selisih,
            lastModified: now,
            isSynced: 0,
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi masuk diperbarui')),
      );
    }
    await _refresh();
  }

  Future<void> _deleteTrxMasuk(TransaksiMasukLocal trx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi Masuk?'),
        content: Text('Kode: ${trx.kodeTransaksi}\nJumlah: ${trx.jumlah} pcs'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();

    // Kurangi stok barang
    final barang = await _barangDao.getByServerId(trx.barangServerId ?? 0);
    if (barang != null) {
      await _barangDao.updateBarang(
        barang.copyWith(
          stokSaatIni: barang.stokSaatIni - trx.jumlah,
          lastModified: now,
          isSynced: 0,
        ),
      );
    }

    await _logDeletion(
      entityType: 'transaksi_masuk',
      entityId: trx.id,
      serverId: trx.serverId,
      kode: trx.kodeTransaksi,
      nama: trx.namaBarang ?? '-',
      detail: 'jumlah:${trx.jumlah} tanggal:${trx.tanggal}',
    );

    // Hapus transaksi
    await _masukDao.delete(trx.id ?? 0);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaksi masuk dihapus')));
    }
    await _refresh();
  }

  Future<void> _editTrxKeluar(TransaksiKeluarLocal trx) async {
    final formKey = GlobalKey<FormState>();
    final jumlahCtrl = TextEditingController(text: trx.jumlah.toString());
    final tujuanCtrl = TextEditingController(text: trx.tujuan ?? '');
    final ketCtrl = TextEditingController(text: trx.keterangan ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Transaksi Keluar'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: trx.kodeTransaksi,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Kode'),
                ),
                TextFormField(
                  initialValue: trx.tanggal,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                ),
                TextFormField(
                  controller: tujuanCtrl,
                  decoration: const InputDecoration(labelText: 'Tujuan'),
                ),
                TextFormField(
                  controller: jumlahCtrl,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      _validatePositiveInt(v, fieldLabel: 'Jumlah'),
                ),
                TextFormField(
                  controller: ketCtrl,
                  decoration: const InputDecoration(labelText: 'Keterangan'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();
    final newJumlah = int.parse(jumlahCtrl.text.trim());
    final oldJumlah = trx.jumlah;
    final selisih = oldJumlah - newJumlah; // Balik, karena keluar

    // Update transaksi
    await _keluarDao.update(
      trx.copyWith(
        tujuan: tujuanCtrl.text.trim().isEmpty ? null : tujuanCtrl.text.trim(),
        jumlah: newJumlah,
        keterangan: ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
        lastModified: now,
        isSynced: 0,
      ),
    );

    // Update stok barang jika jumlah berubah
    if (selisih != 0) {
      final barang = await _barangDao.getByServerId(trx.barangServerId ?? 0);
      if (barang != null) {
        await _barangDao.updateBarang(
          barang.copyWith(
            stokSaatIni: barang.stokSaatIni + selisih,
            lastModified: now,
            isSynced: 0,
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi keluar diperbarui')),
      );
    }
    await _refresh();
  }

  Future<void> _deleteTrxKeluar(TransaksiKeluarLocal trx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi Keluar?'),
        content: Text('Kode: ${trx.kodeTransaksi}\nJumlah: ${trx.jumlah} pcs'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final now = DateTime.now().toIso8601String();

    // Kembalikan stok barang (transaksi keluar dihapus = stok naik)
    final barang = await _barangDao.getByServerId(trx.barangServerId ?? 0);
    if (barang != null) {
      await _barangDao.updateBarang(
        barang.copyWith(
          stokSaatIni: barang.stokSaatIni + trx.jumlah,
          lastModified: now,
          isSynced: 0,
        ),
      );
    }

    await _logDeletion(
      entityType: 'transaksi_keluar',
      entityId: trx.id,
      serverId: trx.serverId,
      kode: trx.kodeTransaksi,
      nama: trx.namaBarang ?? '-',
      detail: 'jumlah:${trx.jumlah} tanggal:${trx.tanggal}',
    );

    // Hapus transaksi
    await _keluarDao.delete(trx.id ?? 0);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaksi keluar dihapus')));
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 64,
        actionsIconTheme: const IconThemeData(size: 22),
        title: const Text('WMS Offline-First'),
        actions: [
          IconButton(
            onPressed: _showSyncStatus,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Status sinkronisasi',
          ),
          IconButton(
            onPressed: _loading ? null : _sync,
            icon: const Icon(Icons.sync),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu lainnya',
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportToCSV();
                  break;
                case 'delete_log':
                  _showDeletionHistory();
                  break;
                case 'error_log':
                  _showErrorLog();
                  break;
                case 'settings':
                  _openSettings();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export ke CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_log',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep_outlined),
                  title: Text('Riwayat hapus (30 hari)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'error_log',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Riwayat Error Log'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings & Maintenance'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Barang', icon: Icon(Icons.inventory_2)),
              Tab(text: 'Masuk', icon: Icon(Icons.call_received)),
              Tab(text: 'Keluar', icon: Icon(Icons.call_made)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _openAddMenu,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          _buildDashboardSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Barang
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        onChanged: _filterBarang,
                        decoration: InputDecoration(
                          hintText: 'Cari kode/nama barang...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: _itemsFiltered.length,
                          itemBuilder: (_, i) {
                            final b = _itemsFiltered[i];
                            return ListTile(
                              title: Text(b.namaBarang),
                              subtitle: Text(
                                '${b.kodeBarang} · Stok: ${b.stokSaatIni}',
                              ),
                              onTap: () => _editBarang(b),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    b.isSynced == 1
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    color: b.isSynced == 1
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  PopupMenuButton(
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        child: const Text('Edit'),
                                        onTap: () => _editBarang(b),
                                      ),
                                      PopupMenuItem(
                                        child: const Text('Hapus'),
                                        onTap: () => _deleteBarang(b),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Tab Transaksi Masuk
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: _itemsMasuk.isEmpty
                      ? const Center(child: Text('Belum ada transaksi masuk'))
                      : ListView.builder(
                          itemCount: _itemsMasuk.length,
                          itemBuilder: (_, i) {
                            final m = _itemsMasuk[i];
                            return ListTile(
                              title: Text(m.kodeTransaksi),
                              subtitle: Text(
                                '${m.namaBarang ?? '-'} · ${m.tanggal} · ${m.supplier ?? '-'} · ${m.jumlah} pcs',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    child: const Text('Edit'),
                                    onTap: () => _editTrxMasuk(m),
                                  ),
                                  PopupMenuItem(
                                    child: const Text('Hapus'),
                                    onTap: () => _deleteTrxMasuk(m),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Tab Transaksi Keluar
                RefreshIndicator(
                  onRefresh: _refresh,
                  child: _itemsKeluar.isEmpty
                      ? const Center(child: Text('Belum ada transaksi keluar'))
                      : ListView.builder(
                          itemCount: _itemsKeluar.length,
                          itemBuilder: (_, i) {
                            final k = _itemsKeluar[i];
                            return ListTile(
                              title: Text(k.kodeTransaksi),
                              subtitle: Text(
                                '${k.namaBarang ?? '-'} · ${k.tanggal} · ${k.tujuan ?? '-'} · ${k.jumlah} pcs',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    child: const Text('Edit'),
                                    onTap: () => _editTrxKeluar(k),
                                  ),
                                  PopupMenuItem(
                                    child: const Text('Hapus'),
                                    onTap: () => _deleteTrxKeluar(k),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Pending sync (barang+stok+transaksi): $_pendingCount'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary() {
    final cards = [
      _summaryCard(
        label: 'Barang',
        value: _items.length.toString(),
        icon: Icons.inventory_2,
        color: Colors.blue,
        onTap: () => _showSummaryDetail('barang'),
      ),
      _summaryCard(
        label: 'Stok Total',
        value: _calculateTotalStock().toString(),
        icon: Icons.storage,
        color: Colors.indigo,
        onTap: () => _showSummaryDetail('stok'),
      ),
      _summaryCard(
        label: 'Pending',
        value: _pendingCount.toString(),
        icon: Icons.cloud_off,
        color: Colors.orange,
        onTap: () => _showSummaryDetail('pending'),
      ),
      _summaryCard(
        label: 'Sinkron',
        value: _getLastSyncText(),
        icon: Icons.history,
        color: Colors.green,
        onTap: () => _showSummaryDetail('sync'),
      ),
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SizedBox(
        height: 160,
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateTotalStock() {
    return _items.fold<int>(0, (sum, b) => sum + b.stokSaatIni);
  }

  String _getLastSyncText() {
    final times = [_lastPush, _lastPull].whereType<DateTime>();
    if (times.isEmpty) return 'Belum';
    final latest = times.reduce((a, b) => a.isAfter(b) ? a : b);
    final diff = DateTime.now().difference(latest);
    if (diff.inMinutes < 1) return 'Baru';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    await _refresh();
    await _loadSyncStatus();
  }

  void _showSummaryDetail(String type) {
    late Widget content;
    String title;

    switch (type) {
      case 'barang':
        title = 'Total Barang';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jumlah: ${_items.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Top 5 berdasarkan stok:'),
            const SizedBox(height: 4),
            ..._items
                .take(5)
                .map(
                  (b) => Text(
                    '${b.namaBarang} (${b.kodeBarang}) · stok ${b.stokSaatIni}',
                  ),
                ),
          ],
        );
        break;
      case 'stok':
        title = 'Stok Total';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok agregat: ${_calculateTotalStock()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan: stok dihitung dari master barang dan update otomatis saat transaksi masuk/keluar.',
            ),
          ],
        );
        break;
      case 'pending':
        title = 'Pending Sinkronisasi';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total pending: $_pendingCount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Barang: $_pendingBarangCount'),
            Text('Stok: $_pendingStokCount'),
            Text('Transaksi Masuk: $_pendingMasukCount'),
            Text('Transaksi Keluar: $_pendingKeluarCount'),
          ],
        );
        break;
      default:
        title = 'Sinkron Terakhir';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Push: ${_formatDateTime(_lastPush)}'),
            Text('Pull: ${_formatDateTime(_lastPull)}'),
            const SizedBox(height: 8),
            const Text('Tekan tombol sync untuk memaksa push+pull ulang.'),
          ],
        );
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              content,
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeletionHistory() async {
    await _deleteLogDao.purgeOlderThan(30);
    final logs = await _deleteLogDao.getRecent(limit: 100);
    if (!mounted) return;
    setState(() => _deleteLogs = logs);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        List<DeletionLogLocal> localLogs = List.of(_deleteLogs);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Riwayat Hapus (otomatis 30 hari)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Log dihapus otomatis setelah 30 hari. Gunakan tombol bersihkan untuk hapus segera.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await _deleteLogDao.clearAll();
                                setState(() => _deleteLogs = []);
                                setModalState(() => localLogs = []);
                              },
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Bersihkan sekarang'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: localLogs.isEmpty
                              ? const Center(
                                  child: Text('Belum ada riwayat hapus'),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: localLogs.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final log = localLogs[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        '${log.kode} · ${log.nama}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${log.entityType} · ${log.deletedAt}\n${log.detail ?? '-'}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showErrorLog() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Error Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${_errorLogs.length} error',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_errorLogs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Belum ada error'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _errorLogs.length,
                          itemBuilder: (ctx, i) {
                            final log = _errorLogs[i];
                            final timestamp = log['timestamp'] ?? '';
                            final error = log['error'] ?? '';
                            final raw = log['raw'] ?? '';

                            final dt = DateTime.tryParse(timestamp);
                            final formattedTime = dt != null
                                ? _formatDateTime(dt)
                                : timestamp;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ExpansionTile(
                                title: Text(
                                  error,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                subtitle: Text(
                                  formattedTime,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Raw Error:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: SelectableText(
                                            raw,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    if (_errorLogs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() => _errorLogs = []);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Hapus semua error log'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSyncStatus() async {
    await _loadSyncStatus();
    if (!mounted) return;
    String? healthText; // Initialize as null, not from _healthStatus
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Sinkronisasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Terakhir push: ${_formatDateTime(_lastPush)}'),
                    Text('Terakhir pull: ${_formatDateTime(_lastPull)}'),
                    const SizedBox(height: 12),
                    if (healthText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lastRawError != null
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          border: Border.all(
                            color: _lastRawError != null
                                ? Colors.red.shade300
                                : Colors.green.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _lastRawError != null
                                  ? Icons.error
                                  : Icons.check_circle,
                              color: _lastRawError != null
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                healthText!,
                                style: TextStyle(
                                  color: _lastRawError != null
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final repo = await _makeSyncRepo();
                          try {
                            final msg = await repo.checkHealth();
                            if (!mounted) return;
                            setState(() {
                              _healthStatus = msg;
                              _lastRawError = null;
                            });
                            setModalState(() => healthText = msg);
                          } catch (e) {
                            final rawMsg = e.toString();
                            final formatted = _formatErrorMessage(e);
                            final timestamp = DateTime.now().toIso8601String();
                            if (!mounted) return;
                            setState(() {
                              _healthStatus = formatted;
                              _lastRawError = rawMsg;
                              _errorLogs.insert(0, {
                                'timestamp': timestamp,
                                'error': formatted,
                                'raw': rawMsg,
                              });
                              if (_errorLogs.length > 50) {
                                _errorLogs.removeLast();
                              }
                            });
                            setModalState(() => healthText = formatted);
                          }
                        },
                        icon: const Icon(Icons.favorite),
                        label: const Text('Cek Health'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final filename = 'wms_export_$timestamp.csv';

      // Prepare Barang data
      final barangList = <List<dynamic>>[];
      barangList.add(['BARANG DATA', '', '', '', '']);
      barangList.add(['Kode', 'Nama', 'Harga', 'Kategori', 'Satuan']);
      for (var b in _items) {
        barangList.add([
          b.kodeBarang,
          b.namaBarang,
          b.harga?.toString() ?? '',
          b.kategori ?? '',
          b.satuan ?? '',
        ]);
      }

      barangList.add(['', '', '', '', '']);
      barangList.add(['STOK DATA', '', '', '', '']);
      barangList.add(['Kode Barang', 'Jumlah', 'Catatan', '', '']);
      for (var s in _items) {
        barangList.add([
          s.kodeBarang,
          s.stokSaatIni?.toString() ?? '0',
          s.lastModified ?? '',
          '',
          '',
        ]);
      }

      barangList.add(['', '', '', '', '']);
      barangList.add(['TRANSAKSI MASUK', '', '', '', '']);
      barangList.add(['Kode', 'Tanggal', 'Jumlah', 'Supplier', 'Status']);
      for (var m in _itemsMasuk) {
        barangList.add([
          m.kodeTransaksi,
          m.tanggal,
          m.jumlah?.toString() ?? '',
          m.supplier ?? '',
          m.isSynced == 1 ? 'Synced' : 'Pending',
        ]);
      }

      barangList.add(['', '', '', '', '']);
      barangList.add(['TRANSAKSI KELUAR', '', '', '', '']);
      barangList.add(['Kode', 'Tanggal', 'Jumlah', 'Tujuan', 'Status']);
      for (var k in _itemsKeluar) {
        barangList.add([
          k.kodeTransaksi,
          k.tanggal,
          k.jumlah?.toString() ?? '',
          k.tujuan ?? '',
          k.isSynced == 1 ? 'Synced' : 'Pending',
        ]);
      }

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(barangList);

      // Get Documents directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File CSV berhasil disimpan: $filename'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () async {
              await Share.shareXFiles([XFile(file.path)], text: 'WMS Export');
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
