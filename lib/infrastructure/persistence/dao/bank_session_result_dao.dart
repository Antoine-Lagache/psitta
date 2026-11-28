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

/// Reads session aggregates with their original bank and commit context.
final class BankSessionResultDao {
  Future<BankSessionResult?> getById(
    sqlite.SqliteReadContext database,
    SessionResultId id,
  ) async {
    final rows = await database.getAll('SELECT * FROM session_result WHERE id = ?', [
      id.value,
    ]);
    if (rows.isEmpty) return null;
    final row = rows.single;
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
}
