import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/content/media_persistence.dart';

// TODO : add a getByChecksum method
class MediaDao {
  final sqlite.SqliteDatabase database;

  MediaDao(this.database);

  Future<int> insert(MediaPersistence media) {
    if (media.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final mediaResult = await txn.execute(
        '''
        INSERT INTO media (
          path,
          mime_type,
          size,
          checksum,
        )
        VALUES (?, ?, ?, ?)
        RETURNING id
      ''',
        [media.path, media.mimeType, media.size, media.checksum],
      );

      return mediaResult.first['id'] as int;
    });
  }

  Future<MediaPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final mediaRows = await txn.getAll(
        '''
        SELECT
          id,
          path,
          mime_type,
          size,
          checksum
        FROM media
        WHERE id = ?
        ''',
        [id],
      );

      if (mediaRows.isEmpty) {
        return null;
      }

      return MediaPersistence.fromRow(mediaRows.first);
    });
  }

  Future<void> update(MediaPersistence media) {
    if (media.id == null) {
      throw ArgumentError('Cannot update a Media without an id');
    }

    final mediaId = media.id!;

    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        UPDATE media
        SET
          path = ?,
          mime_type = ?,
          size = ?,
          checksum = ?
        WHERE id = ?
        ''',
        [media.path, media.mimeType, media.size, media.checksum, mediaId],
      );
    });
  }

  Future<void> delete(int id) async {
    await database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM media
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
