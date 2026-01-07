// Model entity transaksi masuk lokal
class TransaksiMasukLocal {
  final int? id;
  final int? serverId;
  final String kodeTransaksi;
  final String tanggal;
  final String? supplier;
  final int? barangServerId;
  final String? namaBarang;
  final int jumlah;
  final double? hargaBeli;
  final String? keterangan;
  final String lastModified;
  final int isSynced;

  TransaksiMasukLocal({
    this.id,
    this.serverId,
    required this.kodeTransaksi,
    required this.tanggal,
    this.supplier,
    this.barangServerId,
    this.namaBarang,
    required this.jumlah,
    this.hargaBeli,
    this.keterangan,
    required this.lastModified,
    this.isSynced = 0,
  });

  TransaksiMasukLocal copyWith({
    int? id,
    int? serverId,
    String? kodeTransaksi,
    String? tanggal,
    String? supplier,
    int? barangServerId,
    String? namaBarang,
    int? jumlah,
    double? hargaBeli,
    String? keterangan,
    String? lastModified,
    int? isSynced,
  }) {
    return TransaksiMasukLocal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      kodeTransaksi: kodeTransaksi ?? this.kodeTransaksi,
      tanggal: tanggal ?? this.tanggal,
      supplier: supplier ?? this.supplier,
      barangServerId: barangServerId ?? this.barangServerId,
      namaBarang: namaBarang ?? this.namaBarang,
      jumlah: jumlah ?? this.jumlah,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      keterangan: keterangan ?? this.keterangan,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory TransaksiMasukLocal.fromMap(Map<String, dynamic> map) {
    return TransaksiMasukLocal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      kodeTransaksi: map['kode_transaksi'] ?? '',
      tanggal: map['tanggal'] ?? '',
      supplier: map['supplier'],
      barangServerId: map['barang_server_id'] as int?,
      namaBarang: map['nama_barang'],
      jumlah: map['jumlah'] ?? 0,
      hargaBeli: (map['harga_beli'] ?? 0).toDouble(),
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
      'supplier': supplier,
      'barang_server_id': barangServerId,
      'nama_barang': namaBarang,
      'jumlah': jumlah,
      'harga_beli': hargaBeli,
      'keterangan': keterangan,
      'last_modified': lastModified,
      'is_synced': isSynced,
    };
  }
}
