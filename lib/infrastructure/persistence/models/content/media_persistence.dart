class MediaPersistence {
  final int? id;
  final String path;
  final String mimeType;
  final int size;
  final String sha256;

  MediaPersistence({
    this.id,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.sha256,
  });

  factory MediaPersistence.fromRow(Map<String, Object?> mediaRow) {
    return MediaPersistence(
      id: mediaRow['id'] as int?,
      path: mediaRow['path'] as String,
      mimeType: mediaRow['mime_type'] as String,
      size: mediaRow['size'] as int,
      sha256: mediaRow['sha256'] as String,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'path': path,
      'mime_type': mimeType,
      'size': size,
      'sha256': sha256,
    };
  }
}
