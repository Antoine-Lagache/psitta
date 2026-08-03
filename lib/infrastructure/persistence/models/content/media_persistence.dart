class MediaPersistence {
  final int? id;
  final String path;
  final String mimeType;
  final int size;
  final String? checksum;

  MediaPersistence({
    this.id,
    required this.path,
    required this.mimeType,
    required this.size,
    this.checksum,
  });

  factory MediaPersistence.fromRow(Map<String, Object?> mediaRow) {
    return MediaPersistence(
      id: mediaRow['id'] as int?,
      path: mediaRow['path'] as String,
      mimeType: mediaRow['mime_type'] as String,
      size: mediaRow['size'] as int,
      checksum: mediaRow['checksum'] as String?,
    );
  }

  Map<String, Object?> toRow() {
    return {'id': id, 'path': path, 'mime_type': mimeType, 'size': size, 'checksum': checksum};
  }
}
