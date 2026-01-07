// Model entity transaksi keluar lokal
class TransaksiKeluarLocal {
  final int? id;
  final int? serverId;
  final String kodeTransaksi;
  final String tanggal;
  final String? tujuan;
  final int? barangServerId;
  final String? namaBarang;
  final int jumlah;
  final String? keterangan;
  final String lastModified;
  final int isSynced;

  TransaksiKeluarLocal({
    this.id,
    this.serverId,
    required this.kodeTransaksi,
    required this.tanggal,
    this.tujuan,
    this.barangServerId,
    this.namaBarang,
    required this.jumlah,
    this.keterangan,
    required this.lastModified,
    this.isSynced = 0,
  });

  TransaksiKeluarLocal copyWith({
    int? id,
    int? serverId,
    String? kodeTransaksi,
    String? tanggal,
    String? tujuan,
    int? barangServerId,
    String? namaBarang,
    int? jumlah,
    String? keterangan,
    String? lastModified,
    int? isSynced,
  }) {
    return TransaksiKeluarLocal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      kodeTransaksi: kodeTransaksi ?? this.kodeTransaksi,
      tanggal: tanggal ?? this.tanggal,
      tujuan: tujuan ?? this.tujuan,
      barangServerId: barangServerId ?? this.barangServerId,
      namaBarang: namaBarang ?? this.namaBarang,
      jumlah: jumlah ?? this.jumlah,
      keterangan: keterangan ?? this.keterangan,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory TransaksiKeluarLocal.fromMap(Map<String, dynamic> map) {
    return TransaksiKeluarLocal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      kodeTransaksi: map['kode_transaksi'] ?? '',
      tanggal: map['tanggal'] ?? '',
      tujuan: map['tujuan'],
      barangServerId: map['barang_server_id'] as int?,
      namaBarang: map['nama_barang'],
      jumlah: map['jumlah'] ?? 0,
      keterangan: map['keterangan'],
      lastModified: map['last_modified'] ?? '',
      isSynced: map['is_synced'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'kode_transaksi': kodeTransaksi,
      'tanggal': tanggal,
      'tujuan': tujuan,
      'barang_server_id': barangServerId,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'last_modified': lastModified,
      'is_synced': isSynced,
    };
  }
}
