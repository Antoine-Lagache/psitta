import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Reads resumable exercises once their progression references are migrated.
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
    return rows.map((row) {
      final id = row['exercise_progress_id'] as int?;
      if (id == null) {
        throw StateError('Session $sessionId contains an unmigrated exercise');
      }
      return ExerciseResume(
        exerciseId: ExerciseProgressId(id),
        status: ExerciseStatus.fromCode(row['status_index'] as int),
        trainingCount: row['training_count'] as int?,
      );
    }).toList(growable: false);
  }
}
