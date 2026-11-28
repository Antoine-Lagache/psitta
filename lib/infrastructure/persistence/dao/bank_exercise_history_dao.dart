import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef BankHistoryEntry = ({
  ExerciseHistoryId? id,
  ExerciseProgressId exerciseId,
  SentenceId? sentenceId,
  Grade grade,
  DateTime answeredAt,
  ExerciseStatus status,
});

/// Persists answer events with exact editorial sentence references.
final class BankExerciseHistoryDao {
  Future<List<BankHistoryEntry>> getList(
    sqlite.SqliteReadContext database, {
    ExerciseProgressId? exerciseId,
    String? startDate,
    String? endDate,
  }) async {
    final conditions = ['exercise_progress_id IS NOT NULL'];
    final parameters = <Object?>[];
    if (exerciseId != null) {
      conditions.add('exercise_progress_id = ?');
      parameters.add(exerciseId.value);
    }
    if (startDate != null) {
      conditions.add('answered_at >= ?');
      parameters.add(startDate);
    }
    if (endDate != null) {
      conditions.add('answered_at < ?');
      parameters.add(endDate);
    }
    final rows = await database.getAll('''
      SELECT * FROM exercise_history WHERE ${conditions.join(' AND ')}
      ORDER BY answered_at DESC, id DESC
      ''', parameters);
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

  Future<BankHistoryEntry?> getById(
    sqlite.SqliteReadContext database,
    ExerciseHistoryId id,
  ) async {
    final rows = await database.getAll(
      'SELECT * FROM exercise_history WHERE id = ? AND exercise_progress_id IS NOT NULL',
      [id.value],
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  Future<ExerciseHistoryId> insert(
    sqlite.SqliteWriteContext transaction,
    BankHistoryEntry entry,
  ) async {
    if (entry.id != null) throw ArgumentError('History already has an ID');
    final rows = await transaction.execute(
      '''
      INSERT INTO exercise_history (
        exercise_progress_id, sentence_commit_uid, sentence_change_id,
        grade, answered_at, status
      ) VALUES (?, ?, ?, ?, ?, ?) RETURNING id
      ''',
      [
        entry.exerciseId.value,
        entry.sentenceId?.commitUid.value,
        entry.sentenceId?.changeId,
        entry.grade.toInt(),
        toIsoUtc(entry.answeredAt),
        entry.status.code,
      ],
    );
    return ExerciseHistoryId(rows.single['id'] as int);
  }

  Future<void> insertAll(
    sqlite.SqliteWriteContext transaction,
    List<BankHistoryEntry> history,
  ) async {
    for (final entry in history) {
      await insert(transaction, entry);
    }
  }

  Future<bool> hasHistory(
    sqlite.SqliteReadContext database,
    ExerciseProgressId id,
  ) async {
    final rows = await database.getAll(
      'SELECT 1 FROM exercise_history WHERE exercise_progress_id = ? LIMIT 1',
      [id.value],
    );
    return rows.isNotEmpty;
  }

  Future<void> delete(sqlite.SqliteWriteContext transaction, ExerciseHistoryId id) async {
    await transaction.execute('DELETE FROM exercise_history WHERE id = ?', [id.value]);
  }

  Future<void> deleteAll(
    sqlite.SqliteWriteContext transaction,
    ExerciseProgressId id,
  ) async {
    await transaction.execute(
      'DELETE FROM exercise_history WHERE exercise_progress_id = ?',
      [id.value],
    );
  }
}
