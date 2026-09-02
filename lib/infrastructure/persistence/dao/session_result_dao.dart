import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/session_result/session_result_persistence.dart';

/// Stores session aggregates and their normalized per-status counts.
class SessionResultDao {
  final sqlite.SqliteDatabase database;

  SessionResultDao(this.database);

  /// Inserts a result within the caller's session transaction.
  Future<int> insert(
    SessionResultPersistence sessionResult,
    sqlite.SqliteWriteContext txn,
  ) async {
    if (sessionResult.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    final result = await txn.execute(
      '''
        INSERT INTO session_result (
          session_type_index,
          number_unique_exercises_completed,
          started_at,
          end_at
        )
        VALUES (?, ?, ?, ?)
        RETURNING id
        ''',
      [
        sessionResult.sessionTypeIndex,
        sessionResult.uniqueExercisesCompleted,
        sessionResult.startedAt,
        sessionResult.endAt,
      ],
    );

    final id = result.first['id'] as int;

    for (final statusCount in sessionResult.statusCounts) {
      await txn.execute(
        '''
          INSERT INTO session_result_status_count (
            id_session_result,
            status_index,
            number_exercise_completed
          )
          VALUES (?, ?, ?)
          ''',
        [id, statusCount.statusCode, statusCount.exercisesCompleted],
      );
    }

    return id;
  }

  Future<SessionResultPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final resultRows = await txn.getAll(
        '''
        SELECT
          id,
          session_type_index,
          number_unique_exercises_completed,
          started_at,
          end_at
        FROM session_result
        WHERE id = ?
        ''',
        [id],
      );

      if (resultRows.isEmpty) {
        return null;
      }

      final statusRows = await txn.getAll(
        '''
        SELECT
          id_session_result,
          status_index,
          number_exercise_completed
        FROM session_result_status_count
        WHERE id_session_result = ?
        ''',
        [id],
      );

      return SessionResultPersistence.fromRow(resultRows.first, statusRows);
    });
  }

  Future<List<SessionResultPersistence>> getList({String? startDate, String? endDate}) {
    return database.readTransaction((txn) async {
      final conditions = <String>[];
      final parameters = <Object?>[];

      if (startDate != null) {
        conditions.add('started_at >= ?');
        parameters.add(startDate);
      }

      if (endDate != null) {
        conditions.add('started_at < ?');
        parameters.add(endDate);
      }

      final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final resultRows = await txn.getAll('''
        SELECT
          id,
          session_type_index,
          number_unique_exercises_completed,
          started_at,
          end_at
        FROM session_result
        $whereClause
        ORDER BY started_at ASC
      ''', parameters);

      final results = <SessionResultPersistence>[];

      for (final row in resultRows) {
        final int id = row['id'] as int;

        final statusRows = await txn.getAll(
          '''
            SELECT
              id_session_result,
              status_index,
              number_exercise_completed
            FROM session_result_status_count
            WHERE id_session_result = ?
          ''',
          [id],
        );

        results.add(SessionResultPersistence.fromRow(row, statusRows));
      }

      return results;
    });
  }

  /// Replaces a result and its status counts in the caller's transaction.
  Future<void> update(
    SessionResultPersistence sessionResult,
    sqlite.SqliteWriteContext txn,
  ) async {
    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a SessionResult without an id');
    }
    final int id = sessionResult.id!;
    await txn.execute(
      '''
        UPDATE session_result
        SET
          session_type_index = ?,
          number_unique_exercises_completed = ?,
          started_at = ?,
          end_at = ?
        WHERE id = ?
        ''',
      [
        sessionResult.sessionTypeIndex,
        sessionResult.uniqueExercisesCompleted,
        sessionResult.startedAt,
        sessionResult.endAt,
        id,
      ],
    );

    await txn.execute(
      '''
        DELETE FROM session_result_status_count
        WHERE id_session_result = ?
        ''',
      [id],
    );

    for (final statusCount in sessionResult.statusCounts) {
      await txn.execute(
        '''
          INSERT INTO session_result_status_count (
            id_session_result,
            status_index,
            number_exercise_completed
          )
          VALUES (?, ?, ?)
          ''',
        [id, statusCount.statusCode, statusCount.exercisesCompleted],
      );
    }
  }

  Future<void> delete(int id) {
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        DELETE FROM session_result
        WHERE id = ?
        ''',
        [id],
      );
    });
  }
}
