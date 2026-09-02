import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/content/content_persistence.dart';

/// Reads and writes content together with its ordered field values.
class ContentDao {
  final sqlite.SqliteDatabase database;

  ContentDao(this.database);

  /// Inserts a content aggregate and returns only the new content identifier.
  Future<int> insert(ContentPersistence content) {
    if (content.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final contentResult = await txn.execute('''
        INSERT INTO content DEFAULT VALUES
        RETURNING id
        ''');

      final contentId = contentResult.first['id'] as int;

      for (final fieldValue in content.fieldValues) {
        final media = fieldValue.media;
        int? mediaId = media?.id;

        if (media != null && media.id == null) {
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

          mediaId = mediaResult.first['id'] as int;
        }

        await txn.execute(
          '''
          INSERT INTO field_value (
            content_id,
            field_definition_id,
            text_value,
            media_id,
            display_order
          )
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            contentId,
            fieldValue.fieldDefinitionId,
            fieldValue.textValue,
            mediaId,
            fieldValue.displayOrder,
          ],
        );
      }

      return contentId;
    });
  }

  Future<ContentPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final contentRows = await txn.getAll(
        '''
        SELECT
          id
        FROM content
        WHERE id = ?
        ''',
        [id],
      );

      if (contentRows.isEmpty) {
        return null;
      }

      final fieldRows = await txn.getAll(
        '''
        SELECT
          fv.id,
          fv.field_definition_id,
          fv.text_value,
          fv.display_order,

          m.id AS media_id,
          m.path,
          m.mime_type,
          m.size,
          m.sha256

        FROM field_value fv

        LEFT JOIN media m
          ON fv.media_id = m.id

        WHERE fv.content_id = ?
        ORDER BY fv.display_order
        ''',
        [id],
      );

      final fields = fieldRows.map((row) {
        Map<String, Object?>? mediaRow;

        if (row['media_id'] != null) {
          mediaRow = {
            'id': row['media_id'],
            'path': row['path'],
            'mime_type': row['mime_type'],
            'size': row['size'],
            'sha256': row['sha256'],
          };
        }

        return FieldValuePersistence.fromRow(row, mediaRow);
      }).toList();

      return ContentPersistence.fromRow(contentRows.first, fields);
    });
  }

  Future<void> update(ContentPersistence content) {
    if (content.id == null) {
      throw ArgumentError('Cannot update a Content without an id');
    }

    final contentId = content.id!;

    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM field_value
        WHERE content_id = ?
        ''',
        [contentId],
      );

      for (final fieldValue in content.fieldValues) {
        final media = fieldValue.media;

        int? mediaId = media?.id;

        if (media != null && media.id == null) {
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

          mediaId = mediaResult.first['id'] as int;
        }

        await txn.execute(
          '''
          INSERT INTO field_value (
            content_id,
            field_definition_id,
            text_value,
            media_id,
            display_order
          )
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            contentId,
            fieldValue.fieldDefinitionId,
            fieldValue.textValue,
            mediaId,
            fieldValue.displayOrder,
          ],
        );
      }
    });
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM content
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
