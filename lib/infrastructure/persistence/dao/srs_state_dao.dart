import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/srs_state_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Persists FSRS rows by their local progression identity on the target schema.
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

  Future<void> insert(
    sqlite.SqliteWriteContext transaction,
    ExerciseProgressId id,
    SRSState state,
  ) async {
    if (state.exerciseId != id) {
      throw ArgumentError('FSRS state must belong to the requested progression');
    }
    final row = SRSStateMapper.toPersistenceSrsState(state);
    await transaction.execute(
      '''
      INSERT INTO srs_state (
        exercise_progress_id, state, step, stability, difficulty, due, last_review
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id.value,
        row.state,
        row.step,
        row.stability,
        row.difficulty,
        row.due,
        row.lastReview,
      ],
    );
  }

  static const _join = '''
    FROM exercise_progress p
    JOIN srs_state s ON s.exercise_progress_id = p.id
    JOIN bank_change c ON c.commit_uid = p.active_commit_uid
      AND c.change_id = p.active_change_id
    WHERE p.learning_bank_id = ?
    ''';

  Future<List<ExerciseProgressId>> getDueExercises(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
    int nowInMicroseconds,
    int count,
    String? type,
  ) async {
    final typeCondition = type == null
        ? ''
        : "AND json_extract(c.payload_json, '$.exercise_type') = ?";
    final rows = await database.getAll(
      '''
      SELECT p.id $_join
        AND s.last_review IS NOT NULL AND s.due <= ?
        $typeCondition
      ORDER BY s.due ASC, p.id ASC LIMIT ?
      ''',
      [bankId.value, nowInMicroseconds, if (type != null) type, count],
    );
    return rows.map((row) => ExerciseProgressId(row['id'] as int)).toList();
  }

  Future<List<ExerciseProgressId>> getNewExercises(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
    int count,
    String? type,
  ) async {
    final typeCondition = type == null
        ? ''
        : "AND json_extract(c.payload_json, '$.exercise_type') = ?";
    final rows = await database.getAll(
      '''
      SELECT p.id $_join AND s.last_review IS NULL $typeCondition
      ORDER BY json_extract(c.payload_json, '$.priority_order') ASC,
        json_extract(c.payload_json, '$.exercise_id') ASC
      LIMIT ?
      ''',
      [bankId.value, if (type != null) type, count],
    );
    return rows.map((row) => ExerciseProgressId(row['id'] as int)).toList();
  }

  Future<int> countDueExercises(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
    int nowInMicroseconds,
    String? type,
  ) async {
    final typeCondition = type == null
        ? ''
        : "AND json_extract(c.payload_json, '$.exercise_type') = ?";
    final rows = await database.getAll(
      '''
      SELECT COUNT(*) AS count $_join
        AND s.last_review IS NOT NULL AND s.due <= ? $typeCondition
      ''',
      [bankId.value, nowInMicroseconds, if (type != null) type],
    );
    return rows.single['count'] as int;
  }

  Future<int> countNewExercises(
    sqlite.SqliteReadContext database,
    LearningBankId bankId,
    String? type,
  ) async {
    final typeCondition = type == null
        ? ''
        : "AND json_extract(c.payload_json, '$.exercise_type') = ?";
    final rows = await database.getAll(
      'SELECT COUNT(*) AS count $_join AND s.last_review IS NULL $typeCondition',
      [bankId.value, if (type != null) type],
    );
    return rows.single['count'] as int;
  }

  Future<Map<String, ({int notStarted, int started, int mastered})>>
  countProgressByType(sqlite.SqliteReadContext database, LearningBankId bankId) async {
    final rows = await database.getAll(
      '''
      SELECT json_extract(c.payload_json, '$.exercise_type') AS type,
        SUM(CASE WHEN s.last_review IS NULL THEN 1 ELSE 0 END) AS not_started,
        SUM(CASE WHEN s.last_review IS NOT NULL AND
          (s.stability IS NULL OR s.stability <= 30) THEN 1 ELSE 0 END) AS started,
        SUM(CASE WHEN s.stability > 30 THEN 1 ELSE 0 END) AS mastered
      $_join GROUP BY type
      ''',
      [bankId.value],
    );
    return {
      for (final row in rows)
        row['type'] as String: (
          notStarted: row['not_started'] as int,
          started: row['started'] as int,
          mastered: row['mastered'] as int,
        ),
    };
  }
}
