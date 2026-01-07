// Model entity barang lokal
class BarangLocal {
  final int? id;
  final int? serverId;
  final String kodeBarang;
  final String namaBarang;
  final String? kategori;
  final String satuan;
  final double harga;
  final int stokMinimum;
  final int stokSaatIni;
  final String lastModified;
  final int isSynced;

  BarangLocal({
    this.id,
    this.serverId,
    required this.kodeBarang,
    required this.namaBarang,
    this.kategori,
    required this.satuan,
    required this.harga,
    required this.stokMinimum,
    required this.stokSaatIni,
    required this.lastModified,
    this.isSynced = 0,
  });

  BarangLocal copyWith({
    int? id,
    int? serverId,
    String? kodeBarang,
    String? namaBarang,
    String? kategori,
    String? satuan,
    double? harga,
    int? stokMinimum,
    int? stokSaatIni,
    String? lastModified,
    int? isSynced,
  }) {
    return BarangLocal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      namaBarang: namaBarang ?? this.namaBarang,
      kategori: kategori ?? this.kategori,
      satuan: satuan ?? this.satuan,
      harga: harga ?? this.harga,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      stokSaatIni: stokSaatIni ?? this.stokSaatIni,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory BarangLocal.fromMap(Map<String, dynamic> map) {
    return BarangLocal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      kodeBarang: map['kode_barang'] ?? '',
      namaBarang: map['nama_barang'] ?? '',
      kategori: map['kategori'],
      satuan: map['satuan'] ?? '',
      harga: (map['harga'] ?? 0).toDouble(),
      stokMinimum: map['stok_minimum'] ?? 0,
      stokSaatIni: map['stok_saat_ini'] ?? 0,
      lastModified: map['last_modified'] ?? '',
      isSynced: map['is_synced'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'kode_barang': kodeBarang,
      'nama_barang': namaBarang,
      'kategori': kategori,
      'satuan': satuan,
      'harga': harga,
      'stok_minimum': stokMinimum,
      'stok_saat_ini': stokSaatIni,
      'last_modified': lastModified,
      'is_synced': isSynced,
    };
  }
}
