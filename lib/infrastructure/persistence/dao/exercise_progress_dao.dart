import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise_progress_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Stores local progression references; editorial resolution belongs to repositories.
final class ExerciseProgressDao {
  Future<ExerciseProgressReference?> getById(
    sqlite.SqliteReadContext database,
    ExerciseProgressId id,
  ) async {
    final rows = await database.getAll('SELECT * FROM exercise_progress WHERE id = ?', [
      id.value,
    ]);
    return rows.isEmpty ? null : ExerciseProgressMapper.toDomain(rows.single);
  }

  Future<ExerciseProgressReference?> getByExercise(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
    ExerciseId exerciseId,
  ) async {
    final rows = await database.getAll(
      '''
      SELECT * FROM exercise_progress
      WHERE learning_bank_id = ? AND active_commit_uid = ? AND active_change_id = ?
      ''',
      [bankId.value, exerciseId.commitUid.value, exerciseId.changeId],
    );
    return rows.isEmpty ? null : ExerciseProgressMapper.toDomain(rows.single);
  }

  Future<List<ExerciseProgressReference>> getByBank(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
  ) async {
    final rows = await database.getAll(
      'SELECT * FROM exercise_progress WHERE learning_bank_id = ? ORDER BY id',
      [bankId.value],
    );
    return rows.map(ExerciseProgressMapper.toDomain).toList(growable: false);
  }

  Future<ExerciseProgressId> insert(
    sqlite.SqliteWriteContext transaction,
    LearningBankId bankId,
    ExerciseId exerciseId,
  ) async {
    final row = ExerciseProgressMapper.toPersistence(bankId, exerciseId);
    final rows = await transaction.execute(
      '''
      INSERT INTO exercise_progress (
        learning_bank_id, active_commit_uid, active_change_id
      ) VALUES (?, ?, ?) RETURNING id
      ''',
      [row['learning_bank_id'], row['active_commit_uid'], row['active_change_id']],
    );
    return ExerciseProgressId(rows.single['id'] as int);
  }

  /// Deletes local progression and dependent state through foreign keys.
  Future<void> delete(
    sqlite.SqliteWriteContext transaction,
    ExerciseProgressId id,
  ) async {
    await transaction.execute('DELETE FROM exercise_progress WHERE id = ?', [id.value]);
  }
}
