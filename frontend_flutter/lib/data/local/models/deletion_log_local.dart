class DeletionLogLocal {
  final int? id;
  final String entityType;
  final int? entityId;
  final String kode;
  final String nama;
  final String? detail;
  final String deletedAt;

  DeletionLogLocal({
    this.id,
    required this.entityType,
    this.entityId,
    required this.kode,
    required this.nama,
    this.detail,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'kode': kode,
      'nama': nama,
      'detail': detail,
      'deleted_at': deletedAt,
    };
  }

  factory DeletionLogLocal.fromMap(Map<String, dynamic> map) {
    return DeletionLogLocal(
      id: map['id'] as int?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int?,
      kode: map['kode'] as String,
      nama: map['nama'] as String,
      detail: map['detail'] as String?,
      deletedAt: map['deleted_at'] as String,
    );
  }
}
