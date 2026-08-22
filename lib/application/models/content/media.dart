/// Represents a media resource attached to content.
class Media {
  final int? id;
  final String path;
  final String mimeType;
  final int size;
  final String? checksum;

  Media({
    required this.id,
    required this.path,
    required this.mimeType,
    required this.size,
    this.checksum,
  });
}
