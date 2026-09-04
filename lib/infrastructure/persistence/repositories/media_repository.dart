import 'package:psitta/application/models/content/media.dart';
import 'package:psitta/infrastructure/persistence/dao/media_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/content_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Resolves application media metadata by its content hash.
class MediaRepository {
  final sqlite.SqliteDatabase database;
  final MediaDao _mediaDao;

  MediaRepository(this.database) : _mediaDao = MediaDao(database);

  Future<Media?> getBySHA256(String sha256) async {
    final media = await _mediaDao.getBySHA256(sha256);
    return media == null ? null : ContentMapper.mediaToDomain(media);
  }
}
