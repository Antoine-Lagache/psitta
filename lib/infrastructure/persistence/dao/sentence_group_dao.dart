import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class SentenceGroupDao {
  final sqlite.SqliteDatabase database;

  SentenceGroupDao(this.database);

  Future<int> insert(SentenceGroupPersistence sentenceGroup) {
    if (sentenceGroup.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final sentenceGroupResult = await txn.execute('''
        INSERT INTO sentence_group DEFAULT VALUES
        RETURNING id
      ''');

      final int sentenceGroupId = sentenceGroupResult.first['id'];

      for (final instance in sentenceGroup.sentenceInstances) {
        final sentenceInstanceResult = await txn.execute(
          '''
          INSERT INTO sentence_instance (
            sentence_group_id,
            content_id
          )
          VALUES  (?,?)
          RETURNING id
        ''',
          [sentenceGroupId, instance.contentId],
        );

        final int sentenceInstanceId = sentenceInstanceResult.first['id'];

        final SentenceStatePersistence sentenceState = instance.sentenceState;
        await txn.execute(
          '''
          INSERT INTO sentence_state (
            sentence_instance_id,
            shown_count,
            accumulated_score,
            is_in_learning
          )
          VALUES (?, ?, ?, ?)
        ''',
          [
            sentenceInstanceId,
            sentenceState.shownCount,
            sentenceState.accumulatedScore,
            sentenceState.isInLearning ? 1 : 0,
          ],
        );
      }
      return sentenceGroupId;
    });
  }

  Future<SentenceGroupPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final sentenceGroupRow = await txn.getAll(
        '''
        SELECT id
        FROM sentence_group
        WHERE id = ?
      ''',
        [id],
      );

      if (sentenceGroupRow.isEmpty) {
        return null;
      }

      final sentenceInstanceRows = await txn.getAll(
        '''
        SELECT
          si.id,
          si.content_id,
          ss.shown_count,
          ss.accumulated_score,
          ss.is_in_learning
        FROM sentence_instance si
        JOIN sentence_state ss
          ON ss.sentence_instance_id = si.id
        WHERE si.sentence_group_id = ?
      ''',
        [id],
      );

      final List<SentenceInstancePersistence> sentenceInstances = sentenceInstanceRows
          .map((row) {
            return SentenceInstancePersistence.fromRow(row, row);
          })
          .toList();

      return SentenceGroupPersistence.fromRow(sentenceGroupRow.first, sentenceInstances);
    });
  }

  Future<void> update(SentenceGroupPersistence sentenceGroup) {
    if (sentenceGroup.id == null) {
      throw ArgumentError('Cannot update a SentenceGroup without an id');
    }

    final sentenceGroupId = sentenceGroup.id!;

    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
          DELETE FROM sentence_instance
          WHERE sentence_group_id = ?
          ''',
        [sentenceGroupId],
      );

      for (final instance in sentenceGroup.sentenceInstances) {
        final sentenceInstanceResult = await txn.execute(
          '''
          INSERT INTO sentence_instance (
            sentence_group_id,
            content_id
          )
          VALUES  (?,?)
          RETURNING id
        ''',
          [sentenceGroupId, instance.contentId],
        );

        final int sentenceInstanceId = sentenceInstanceResult.first['id'];

        final SentenceStatePersistence sentenceState = instance.sentenceState;
        await txn.execute(
          '''
          INSERT INTO sentence_state (
            sentence_instance_id,
            shown_count,
            accumulated_score,
            is_in_learning
          )
          VALUES (?, ?, ?, ?)
        ''',
          [
            sentenceInstanceId,
            sentenceState.shownCount,
            sentenceState.accumulatedScore,
            sentenceState.isInLearning ? 1 : 0,
          ],
        );
      }
    });
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM sentence_group
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
