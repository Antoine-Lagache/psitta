import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/content/media_persistence.dart';

/// Provides CRUD access to media metadata and hash-based lookup.
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
          sha256
        )
        VALUES (?, ?, ?, ?)
        RETURNING id
      ''',
        [media.path, media.mimeType, media.size, media.sha256],
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
          sha256
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

  Future<MediaPersistence?> getBySHA256(String sha256) {
    return database.readTransaction((txn) async {
      final mediaRows = await txn.getAll(
        '''
        SELECT
          id,
          path,
          mime_type,
          size,
          sha256
        FROM media
        WHERE sha256 = ?
        ''',
        [sha256],
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
          sha256 = ?
        WHERE id = ?
        ''',
        [media.path, media.mimeType, media.size, media.sha256, mediaId],
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
