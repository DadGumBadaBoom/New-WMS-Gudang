class DeletionLogLocal {
  final int? id;
  final String entityType;
  final int? entityId;
  final int? serverId;
  final String kode;
  final String nama;
  final String? detail;
  final String deletedAt;
  final int isSynced;

  DeletionLogLocal({
    this.id,
    required this.entityType,
    this.entityId,
    this.serverId,
    required this.kode,
    required this.nama,
    this.detail,
    required this.deletedAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'server_id': serverId,
      'kode': kode,
      'nama': nama,
      'detail': detail,
      'deleted_at': deletedAt,
      'is_synced': isSynced,
    };
  }

  factory DeletionLogLocal.fromMap(Map<String, dynamic> map) {
    return DeletionLogLocal(
      id: map['id'] as int?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int?,
      serverId: map['server_id'] as int?,
      kode: map['kode'] as String,
      nama: map['nama'] as String,
      detail: map['detail'] as String?,
      deletedAt: map['deleted_at'] as String,
      isSynced: (map['is_synced'] as int?) ?? 0,
    );
  }
}
