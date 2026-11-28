import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/srs/sentence_state.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_instance_progress_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Stores sentence selection state independently for each local exercise.
final class SentenceInstanceProgressDao {
  Future<SentenceProgressEntry?> getById(
    sqlite.SqliteReadContext database,
    SentenceInstanceProgressId id,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT * FROM sentence_instance_progress
      WHERE exercise_progress_id = ? AND sentence_id = ?
      ''',
      [id.exerciseProgressId.value, id.sentenceId],
    );
    return rows.isEmpty ? null : SentenceInstanceProgressMapper.toDomain(rows.single);
  }

  Future<List<SentenceProgressEntry>> getByExercise(
    sqlite.SqliteReadContext database,
    ExerciseProgressId id,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT * FROM sentence_instance_progress
      WHERE exercise_progress_id = ? ORDER BY sentence_id
      ''',
      [id.value],
    );
    return rows.map(SentenceInstanceProgressMapper.toDomain).toList(growable: false);
  }

  Future<void> upsert(
    sqlite.SqliteWriteContext transaction,
    SentenceInstanceProgressId id,
    SentenceState state,
  ) async {
    final row = SentenceInstanceProgressMapper.toPersistence(id, state);
    await transaction.execute(
      '''
      INSERT INTO sentence_instance_progress (
        exercise_progress_id, sentence_id, shown_count, accumulated_score, is_in_learning
      ) VALUES (?, ?, ?, ?, ?)
      ON CONFLICT (exercise_progress_id, sentence_id) DO UPDATE SET
        shown_count = excluded.shown_count,
        accumulated_score = excluded.accumulated_score,
        is_in_learning = excluded.is_in_learning
      ''',
      [
        row['exercise_progress_id'],
        row['sentence_id'],
        row['shown_count'],
        row['accumulated_score'],
        row['is_in_learning'],
      ],
    );
  }

  Future<void> delete(
    sqlite.SqliteWriteContext transaction,
    SentenceInstanceProgressId id,
  ) async {
    await transaction.execute(
      '''
      DELETE FROM sentence_instance_progress
      WHERE exercise_progress_id = ? AND sentence_id = ?
      ''',
      [id.exerciseProgressId.value, id.sentenceId],
    );
  }
}
