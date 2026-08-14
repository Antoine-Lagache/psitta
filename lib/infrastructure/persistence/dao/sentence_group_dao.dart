import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';

class SentenceGroupDao {
  final sqlite.SqliteDatabase database;

  SentenceGroupDao(this.database);

  Future<int> insertSentenceGroup(SentenceGroupPersistence sentenceGroup) {
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

  Future<int> insertSentenceInstance(
    SentenceInstancePersistence sentenceInstance,
    int sentenceGroupId,
  ) {
    if (sentenceInstance.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }
    return database.writeTransaction((txn) async {
      final sentenceInstanceResult = await txn.execute(
        '''
          INSERT INTO sentence_instance (
            sentence_group_id,
            content_id
          )
          VALUES  (?,?)
          RETURNING id
        ''',
        [sentenceGroupId, sentenceInstance.contentId],
      );

      final int sentenceInstanceId = sentenceInstanceResult.first['id'];

      final SentenceStatePersistence sentenceState = sentenceInstance.sentenceState;
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
      return sentenceInstanceId;
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

  Future<void> update(
    sqlite.SqliteWriteContext txn,
    SentenceGroupPersistence sentenceGroup,
  ) async {
    if (sentenceGroup.id == null) {
      throw ArgumentError('Cannot update a SentenceGroup without an id');
    }

    final groupId = sentenceGroup.id!;

    // Get the existing sentence instance IDs.
    final existingRows = await txn.getAll(
      '''
        SELECT id
        FROM sentence_instance
        WHERE sentence_group_id = ?
      ''',
      [groupId],
    );

    final existingIds = existingRows.map((row) => row['id'] as int).toSet();

    final newIds = sentenceGroup.sentenceInstances
        .where((instance) => instance.id != null)
        .map((instance) => instance.id!)
        .toSet();

    // Delete instances that are no longer part of the group.
    for (final id in existingIds.difference(newIds)) {
      await txn.execute(
        '''
          DELETE FROM sentence_instance
          WHERE id = ?
        ''',
        [id],
      );
    }

    // Update existing instances or insert new ones.
    for (final instance in sentenceGroup.sentenceInstances) {
      final int instanceId;

      if (instance.id != null) {
        if (!existingIds.contains(instance.id)) {
          throw StateError(
            'Sentence instance ${instance.id} does not belong to group $groupId',
          );
        }

        instanceId = instance.id!;

        await txn.execute(
          '''
            UPDATE sentence_instance
            SET content_id = ?
            WHERE id = ?
          ''',
          [instance.contentId, instanceId],
        );

        await txn.execute(
          '''
            UPDATE sentence_state
            SET
              shown_count = ?,
              accumulated_score = ?,
              is_in_learning = ?
            WHERE sentence_instance_id = ?
          ''',
          [
            instance.sentenceState.shownCount,
            instance.sentenceState.accumulatedScore,
            instance.sentenceState.isInLearning ? 1 : 0,
            instanceId,
          ],
        );
      } else {
        final result = await txn.execute(
          '''
            INSERT INTO sentence_instance (
              sentence_group_id,
              content_id
            )
            VALUES (?, ?)
            RETURNING id
          ''',
          [groupId, instance.contentId],
        );

        instanceId = result.first['id'] as int;

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
            instanceId,
            instance.sentenceState.shownCount,
            instance.sentenceState.accumulatedScore,
            instance.sentenceState.isInLearning ? 1 : 0,
          ],
        );
      }
    }
  }

  Future<void> updateSentencesState(
    sqlite.SqliteWriteContext txn,
    SentenceGroupPersistence sentenceGroup,
  ) async {
    if (sentenceGroup.id == null) {
      throw ArgumentError('Cannot update a SentenceGroup without an id');
    }

    for (final instance in sentenceGroup.sentenceInstances) {
      if (instance.id == null) {
        throw ArgumentError('Cannot update a SentenceInstance without an id');
      }

      final int sentenceInstanceId = instance.id!;

      final SentenceStatePersistence sentenceState = instance.sentenceState;
      await txn.execute(
        '''
          UPDATE sentence_state
          SET
            shown_count = ?,
            accumulated_score = ?,
            is_in_learning = ?
          WHERE sentence_instance_id = ?
        ''',
        [
          sentenceState.shownCount,
          sentenceState.accumulatedScore,
          sentenceState.isInLearning ? 1 : 0,
          sentenceInstanceId,
        ],
      );
    }
  }

  Future<void> moveSentenceInstance(int sentenceInstanceId, int targetGroupId) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
          UPDATE sentence_instance
          SET
            sentence_group_id = ?
          WHERE id = ?
        ''',
        [targetGroupId, sentenceInstanceId],
      );
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

  Future<void> deleteSentenceInstance(int sentenceInstanceId) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM sentence_instance
        WHERE id = ?
        ''',
        [sentenceInstanceId],
      );
    });
  }
}
