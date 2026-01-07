import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/dao/barang_dao.dart';
import '../data/local/dao/stok_dao.dart';
import '../data/local/dao/transaksi_keluar_dao.dart';
import '../data/local/dao/transaksi_masuk_dao.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController();

  final _barangDao = BarangDao();
  final _stokDao = StokDao();
  final _masukDao = TransaksiMasukDao();
  final _keluarDao = TransaksiKeluarDao();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrlCtrl.text =
        prefs.getString('api_base_url') ?? 'http://192.168.78.2:8080/api';
    _deviceNameCtrl.text = prefs.getString('device_name') ?? 'device-demo';
    setState(() {});
  }

  Future<void> _savePrefs() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrlCtrl.text.trim());
    await prefs.setString('device_name', _deviceNameCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings disimpan')));
    }
    setState(() => _saving = false);
  }

  Future<void> _confirmAndRun(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await action();
    }
  }

  Future<void> _clearPending() async {
    await _barangDao.clearPending();
    await _stokDao.clearPending();
    await _masukDao.clearPending();
    await _keluarDao.clearPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pending (barang/stok/transaksi) dihapus'),
        ),
      );
    }
  }

  Future<void> _resetSyncStatus() async {
    await _barangDao.resetSyncStatus();
    await _stokDao.resetSyncStatus();
    await _masukDao.resetSyncStatus();
    await _keluarDao.resetSyncStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status sync di-reset (semua jadi pending)'),
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    await _barangDao.clearAll();
    await _stokDao.clearAll();
    await _masukDao.clearAll();
    await _keluarDao.clearAll();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua data lokal dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Maintenance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _baseUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.x.x:8080/api',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deviceNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Device Name / ID',
                      hintText: 'device-demo',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _savePrefs,
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text('Maintenance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmAndRun(
                'Hapus Pending?',
                'Semua data dengan status pending (is_synced=0) akan dihapus.',
                _clearPending,
              ),
              icon: const Icon(Icons.cleaning_services),
              label: const Text(
                'Clear pending saja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmAndRun(
                'Reset sync status?',
                'Semua data akan ditandai pending (is_synced=0) untuk dipush ulang.',
                _resetSyncStatus,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reset sync status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmAndRun(
                'Hapus semua data?',
                'Seluruh data lokal akan dihapus permanen.',
                _clearAllData,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Hapus semua data lokal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
