import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/media.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';

/// Provides application-level access to content and its media resources.
class ContentController {
  final ContentRepository _contentRepository;
  final MediaRepository _mediaRepository;

  ContentController({
    required ContentRepository contentRepository,
    required MediaRepository mediaRepository,
  }) : _contentRepository = contentRepository,
       _mediaRepository = mediaRepository;

  Future<Content?> getContentById(int id) => _contentRepository.getById(id);

  Future<Media?> getMediaBySHA256(String sha256) =>
      _mediaRepository.getBySHA256(sha256);
}
