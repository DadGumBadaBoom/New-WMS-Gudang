// Model entity stok lokal
class StokLocal {
  final int? id;
  final int? serverId;
  final int? barangServerId;
  final int jumlah;
  final String? keterangan;
  final String lastModified;
  final int isSynced;

  StokLocal({
    this.id,
    this.serverId,
    this.barangServerId,
    required this.jumlah,
    this.keterangan,
    required this.lastModified,
    this.isSynced = 0,
  });

  StokLocal copyWith({
    int? id,
    int? serverId,
    int? barangServerId,
    int? jumlah,
    String? keterangan,
    String? lastModified,
    int? isSynced,
  }) {
    return StokLocal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      barangServerId: barangServerId ?? this.barangServerId,
      jumlah: jumlah ?? this.jumlah,
      keterangan: keterangan ?? this.keterangan,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory StokLocal.fromMap(Map<String, dynamic> map) {
    return StokLocal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      barangServerId: map['barang_server_id'] as int?,
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
      'barang_server_id': barangServerId,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'last_modified': lastModified,
      'is_synced': isSynced,
    };
  }
}
