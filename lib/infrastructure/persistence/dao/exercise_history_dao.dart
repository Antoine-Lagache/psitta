import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/exercise_history/exercise_history_persistence.dart';

/// Stores immutable answer-history rows and supports filtered history queries.
class ExerciseHistoryDao {
  final sqlite.SqliteDatabase database;

  ExerciseHistoryDao(this.database);

  /// Inserts one history entry and returns its generated identifier.
  Future<int> insert(ExerciseHistoryPersistence history) {
    if (history.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final result = await txn.execute(
        '''
        INSERT INTO exercise_history (
          exercise_id,
          sentence_instance_id,
          grade,
          answered_at,
          status
        )
        VALUES (?, ?, ?, ?, ?)
        RETURNING id
        ''',
        [
          history.exerciseId,
          history.sentenceInstanceId,
          history.grade,
          history.answeredAt,
          history.status,
        ],
      );

      return result.first['id'] as int;
    });
  }

  /// Inserts pending entries within the caller's aggregate transaction.
  Future<void> insertAll(
    sqlite.SqliteWriteContext txn,
    List<ExerciseHistoryPersistence> history,
  ) async {
    for (final persistence in history) {
      if (persistence.id != null) {
        throw ArgumentError('Cannot insert an entity that already has an id');
      }
      await txn.execute(
        '''
        INSERT INTO exercise_history (
          exercise_id,
          sentence_instance_id,
          grade,
          answered_at,
          status
        )
        VALUES (?, ?, ?, ?, ?)
        ''',
        [
          persistence.exerciseId,
          persistence.sentenceInstanceId,
          persistence.grade,
          persistence.answeredAt,
          persistence.status,
        ],
      );
    }
  }

  Future<ExerciseHistoryPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll(
        '''
        SELECT
          id,
          exercise_id,
          sentence_instance_id,
          grade,
          answered_at,
          status
        FROM exercise_history
        WHERE id = ?
        ''',
        [id],
      );

      if (rows.isEmpty) {
        return null;
      }

      return ExerciseHistoryPersistence.fromRow(rows.first);
    });
  }

  Future<List<ExerciseHistoryPersistence>> getList({
    int? exerciseId,
    String? startDate,
    String? endDate,
  }) {
    return database.readTransaction((txn) async {
      final conditions = <String>[];
      final parameters = <Object?>[];

      if (exerciseId != null) {
        conditions.add('exercise_id = ?');
        parameters.add(exerciseId);
      }

      if (startDate != null) {
        conditions.add('answered_at >= ?');
        parameters.add(startDate);
      }

      if (endDate != null) {
        conditions.add('answered_at < ?');
        parameters.add(endDate);
      }

      final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final rows = await txn.getAll('''
      SELECT
        id,
        exercise_id,
        sentence_instance_id,
        grade,
        answered_at,
        status
      FROM exercise_history
      $whereClause
      ORDER BY answered_at DESC
      ''', parameters);

      return rows.map(ExerciseHistoryPersistence.fromRow).toList();
    });
  }

  Future<bool> hasHistory(int exerciseId) {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll(
        '''
        SELECT 1
        FROM exercise_history
        WHERE exercise_id = ?
        ''',
        [exerciseId],
      );

      return rows.isNotEmpty;
    });
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM exercise_history
        WHERE id = ?
        ''',
        [id],
      );
    });
  }

  Future<void> deleteAll(sqlite.SqliteWriteContext txn, int exerciseid) async {
    await txn.execute(
      '''
        DELETE FROM exercise_history
        WHERE exercise_id = ?
        ''',
      [exerciseid],
    );
  }
}
