import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/session_result/session_result_persistence.dart';

class SessionResultDao {
  final sqlite.SqliteDatabase database;

  SessionResultDao(this.database);

  Future<int> insert(SessionResultPersistence sessionResult) {
    if (sessionResult.id != null) {
      throw ArgumentError('Cannot insert an entity that already has an id');
    }

    return database.writeTransaction((txn) async {
      final result = await txn.execute(
        '''
        INSERT INTO session_result (
          number_unique_exercises_completed,
          started_at,
          end_at
        )
        VALUES (?, ?, ?)
        RETURNING id
        ''',
        [
          sessionResult.uniqueExercisesCompleted,
          sessionResult.startedAt?.toIso8601String(),
          sessionResult.endAt?.toIso8601String(),
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
          [id, statusCount.statusIndex, statusCount.exercisesCompleted],
        );
      }

      return id;
    });
  }

  Future<SessionResultPersistence?> getById(int id) {
    return database.readTransaction((txn) async {
      final resultRows = await txn.getAll(
        '''
        SELECT
          id,
          number_unique_exercises_completed,
          started_at,
          end_at
        FROM session_result
        WHERE id = ?
        ''',
        [id],
      );

      resultRows.asMap();

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

  Future<void> update(SessionResultPersistence sessionResult) {
    if (sessionResult.id == null) {
      throw ArgumentError('Cannot update a SessionResult without an id');
    }
    final int id = sessionResult.id!;
    return database.writeTransaction((txn) async {
      await txn.execute(
        '''
        UPDATE session_result
        SET
          number_unique_exercises_completed = ?,
          started_at = ?,
          end_at = ?
        WHERE id = ?
        ''',
        [
          sessionResult.uniqueExercisesCompleted,
          sessionResult.startedAt?.toIso8601String(),
          sessionResult.endAt?.toIso8601String(),
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
          [id, statusCount.statusIndex, statusCount.exercisesCompleted],
        );
      }
    });
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
