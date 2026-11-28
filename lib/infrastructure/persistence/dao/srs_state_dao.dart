import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Reads and updates migrated FSRS rows by their local progression identity.
/// Insertion is deferred until the legacy primary key has been removed.
final class SrsStateDao {
  Future<SRSState?> getById(
    sqlite.SqliteReadContext database,
    ExerciseProgressId id,
  ) async {
    final rows = await database.getAll(
      'SELECT * FROM srs_state WHERE exercise_progress_id = ?',
      [id.value],
    );
    if (rows.isEmpty) return null;
    return SRSStateMapper.toDomainSrsState(
      SrsStatePersistence.fromRow(rows.single),
      exerciseId: id.value,
    );
  }

  Future<void> update(
    sqlite.SqliteWriteContext transaction,
    ExerciseProgressId id,
    SRSState state,
  ) async {
    if (state.exerciseId != id) {
      throw ArgumentError('FSRS state must belong to the requested progression');
    }
    final row = SRSStateMapper.toPersistenceSrsState(state);
    final updated = await transaction.execute(
      '''
      UPDATE srs_state SET state = ?, step = ?, stability = ?, difficulty = ?,
        due = ?, last_review = ?
      WHERE exercise_progress_id = ?
      RETURNING exercise_progress_id
      ''',
      [
        row.state,
        row.step,
        row.stability,
        row.difficulty,
        row.due,
        row.lastReview,
        id.value,
      ],
    );
    if (updated.length != 1) {
      throw StateError('Expected one FSRS state for progression $id');
    }
  }
}
