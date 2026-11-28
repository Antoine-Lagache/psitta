import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/infrastructure/persistence/mappers/session/session_result_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/session_result/session_result_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef BankSessionResult = ({
  LearningBankId bankId,
  CommitUid commitUid,
  SessionResult result,
});

/// Persists session aggregates with their original bank and commit context.
final class BankSessionResultDao {
  Future<BankSessionResult?> getById(
    sqlite.SqliteReadContext database,
    SessionResultId id,
  ) async {
    final rows = await database.getAll('SELECT * FROM session_result WHERE id = ?', [
      id.value,
    ]);
    if (rows.isEmpty) return null;
    return _fromRow(database, rows.single);
  }

  Future<BankSessionResult> _fromRow(
    sqlite.SqliteReadContext database,
    Map<String, Object?> row,
  ) async {
    final id = SessionResultId(row['id'] as int);
    final bank = row['learning_bank_id'] as int?;
    final commit = row['bank_commit_uid'] as String?;
    if (bank == null || commit == null) {
      throw StateError('Session $id has no migrated bank context');
    }
    final counts = await database.getAll(
      'SELECT * FROM session_result_status_count WHERE id_session_result = ?',
      [id.value],
    );
    return (
      bankId: LearningBankId(bank),
      commitUid: CommitUid(commit),
      result: SessionResultMapper.toDomain(SessionResultPersistence.fromRow(row, counts)),
    );
  }

  Future<List<BankSessionResult>> getList(
    sqlite.SqliteReadContext database, {
    String? startDate,
    String? endDate,
    bool completedOnly = false,
  }) async {
    final conditions = <String>[];
    final parameters = <Object?>[];
    if (completedOnly) conditions.add('end_at IS NOT NULL');
    final dateColumn = completedOnly ? 'end_at' : 'started_at';
    if (startDate != null) {
      conditions.add('$dateColumn >= ?');
      parameters.add(startDate);
    }
    if (endDate != null) {
      conditions.add('$dateColumn < ?');
      parameters.add(endDate);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await database.getAll(
      'SELECT * FROM session_result $where ORDER BY started_at ASC',
      parameters,
    );
    return [for (final row in rows) await _fromRow(database, row)];
  }

  Future<SessionResultId> insert(
    sqlite.SqliteWriteContext transaction,
    LearningBankId bankId,
    CommitUid commitUid,
    SessionResult result,
  ) async {
    if (result.id != null) throw ArgumentError('Session already has an ID');
    final row = SessionResultMapper.toPersistence(result);
    final rows = await transaction.execute(
      '''
      INSERT INTO session_result (
        session_type_index, number_unique_exercises_completed,
        total_time_spent_microseconds, started_at, end_at,
        learning_bank_id, bank_commit_uid
      ) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id
      ''',
      [
        row.sessionTypeIndex,
        row.uniqueExercisesCompleted,
        row.totalTimeSpent,
        row.startedAt,
        row.endAt,
        bankId.value,
        commitUid.value,
      ],
    );
    final id = SessionResultId(rows.single['id'] as int);
    await _insertCounts(transaction, id, row);
    return id;
  }

  Future<void> update(
    sqlite.SqliteWriteContext transaction,
    SessionResult result,
  ) async {
    final id = result.id;
    if (id == null) throw ArgumentError('Session has no ID');
    final row = SessionResultMapper.toPersistence(result);
    await transaction.execute(
      '''
      UPDATE session_result SET session_type_index = ?,
        number_unique_exercises_completed = ?, total_time_spent_microseconds = ?,
        started_at = ?, end_at = ? WHERE id = ?
      ''',
      [
        row.sessionTypeIndex,
        row.uniqueExercisesCompleted,
        row.totalTimeSpent,
        row.startedAt,
        row.endAt,
        id.value,
      ],
    );
    await transaction.execute(
      'DELETE FROM session_result_status_count WHERE id_session_result = ?',
      [id.value],
    );
    await _insertCounts(transaction, id, row);
  }

  Future<void> _insertCounts(
    sqlite.SqliteWriteContext transaction,
    SessionResultId id,
    SessionResultPersistence row,
  ) async {
    for (final count in row.statusCounts) {
      await transaction.execute(
        '''
        INSERT INTO session_result_status_count (
          id_session_result, status_index, number_exercise_completed
        ) VALUES (?, ?, ?)
        ''',
        [id.value, count.statusCode, count.answerCount],
      );
    }
  }

  Future<void> delete(
    sqlite.SqliteWriteContext transaction,
    SessionResultId id,
  ) async {
    await transaction.execute('DELETE FROM session_result WHERE id = ?', [id.value]);
  }
}
