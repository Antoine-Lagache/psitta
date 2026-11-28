import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef BankHistoryEntry = ({
  ExerciseHistoryId id,
  ExerciseProgressId exerciseId,
  SentenceId? sentenceId,
  Grade grade,
  DateTime answeredAt,
  ExerciseStatus status,
});

/// Reads migrated history only; legacy rows are not assigned fabricated IDs.
final class BankExerciseHistoryDao {
  Future<List<BankHistoryEntry>> getByExercise(
    sqlite.SqliteReadContext database,
    ExerciseProgressId id,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT * FROM exercise_history WHERE exercise_progress_id = ?
      ORDER BY answered_at DESC, id DESC
      ''',
      [id.value],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  static BankHistoryEntry _fromRow(Map<String, Object?> row) {
    final uid = row['sentence_commit_uid'] as String?;
    final change = row['sentence_change_id'] as int?;
    if ((uid == null) != (change == null)) {
      throw StateError('Incomplete sentence reference in history');
    }
    return (
      id: ExerciseHistoryId(row['id'] as int),
      exerciseId: ExerciseProgressId(row['exercise_progress_id'] as int),
      sentenceId: uid == null ? null : SentenceId((CommitUid(uid), change!)),
      grade: Grade.fromInt(row['grade'] as int),
      answeredAt: safeParseDate(row['answered_at'] as String)!,
      status: ExerciseStatus.fromCode(row['status'] as int),
    );
  }
}
