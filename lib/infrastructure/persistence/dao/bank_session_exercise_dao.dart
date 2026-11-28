import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/infrastructure/persistence/models/session_result/session_exercise_status_count_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Persists resumable exercise snapshots using local progression references.
final class BankSessionExerciseDao {
  Future<List<ExerciseResume>> getAll(
    sqlite.SqliteReadContext database,
    SessionResultId sessionId,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT exercise_progress_id, status_index, training_count
      FROM active_session_exercise WHERE session_result_id = ?
      ORDER BY exercise_progress_id
      ''',
      [sessionId.value],
    );
    return rows
        .map((row) {
          final id = row['exercise_progress_id'] as int?;
          if (id == null) {
            throw StateError('Session $sessionId contains an unmigrated exercise');
          }
          return ExerciseResume(
            exerciseId: ExerciseProgressId(id),
            status: ExerciseStatus.fromCode(row['status_index'] as int),
            trainingCount: row['training_count'] as int?,
          );
        })
        .toList(growable: false);
  }

  Future<void> insertAll(
    sqlite.SqliteWriteContext transaction,
    SessionResultId sessionId,
    List<ExerciseResume> exercises,
  ) async {
    for (final exercise in exercises) {
      await transaction.execute(
        '''
        INSERT INTO active_session_exercise (
          session_result_id, exercise_progress_id, status_index, training_count
        ) VALUES (?, ?, ?, ?)
        ''',
        [
          sessionId.value,
          exercise.exerciseId.value,
          exercise.status.code,
          exercise.trainingCount,
        ],
      );
    }
  }

  Future<List<SessionResultId>> getAllSessionId(sqlite.SqliteReadContext database) async {
    final rows = await database.getAll(
      'SELECT DISTINCT session_result_id FROM active_session_exercise',
    );
    return rows.map((row) => SessionResultId(row['session_result_id'] as int)).toList();
  }

  Future<List<SessionExerciseStatusCountPersistence>> countByStatus(
    sqlite.SqliteReadContext database,
    SessionResultId sessionId,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT status_index, COUNT(*) AS exercise_count
      FROM active_session_exercise WHERE session_result_id = ?
      GROUP BY status_index
      ''',
      [sessionId.value],
    );
    return rows.map(SessionExerciseStatusCountPersistence.fromRow).toList();
  }

  Future<void> deleteAll(
    sqlite.SqliteWriteContext transaction,
    SessionResultId sessionId,
  ) async {
    await transaction.execute(
      'DELETE FROM active_session_exercise WHERE session_result_id = ?',
      [sessionId.value],
    );
  }
}
