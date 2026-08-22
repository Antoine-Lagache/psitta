import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'package:psitta/infrastructure/persistence/models/session_result/session_exercise_persistence.dart';

class SessionExerciseDao {
  final sqlite.SqliteDatabase database;

  SessionExerciseDao(this.database);

  Future<void> insertAll(
    int sessionResultId,
    List<SessionExercisePersistence> exercises,
    sqlite.SqliteWriteContext txn,
  ) async {
    for (final exercise in exercises) {
      await txn.execute(
        '''
          INSERT INTO active_session_exercise (
            session_result_id,
            exercise_id,
            status_index,
            training_count
          )
          VALUES (?, ?, ?, ?)
          ''',
        [
          sessionResultId,
          exercise.exerciseId,
          exercise.statusCode,
          exercise.trainingCount,
        ],
      );
    }
  }

  Future<List<SessionExercisePersistence>> getAll(int sessionResultId) {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll(
        '''
        SELECT
          exercise_id,
          status_index,
          training_count
        FROM active_session_exercise
        WHERE session_result_id = ?
        ''',
        [sessionResultId],
      );

      return rows.map(SessionExercisePersistence.fromRow).toList();
    });
  }

  Future<List<int>> getAllSessionId() {
    return database.readTransaction((txn) async {
      final rows = await txn.getAll('''
        SELECT DISTINCT
          session_result_id
        FROM active_session_exercise
        ''');

      return rows.map((r) => (r['session_result_id'] as int)).toList();
    });
  }

  Future<void> deleteAll(int sessionResultId, sqlite.SqliteWriteContext txn) async {
    await txn.execute(
      '''
        DELETE FROM active_session_exercise
        WHERE session_result_id = ?
        ''',
      [sessionResultId],
    );
  }
}
