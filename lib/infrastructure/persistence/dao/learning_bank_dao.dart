import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/learning_bank.dart';
import 'package:psitta/infrastructure/persistence/mappers/learning_bank_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Local bank installations. Head changes are coordinated by the repository.
final class LearningBankDao {
  Future<LearningBank?> getById(
    sqlite.SqliteReadContext database,
    LearningBankId id,
  ) async {
    final rows = await database.getAll('SELECT * FROM learning_bank WHERE id = ?', [
      id.value,
    ]);
    return rows.isEmpty ? null : LearningBankMapper.toDomain(rows.single);
  }

  Future<List<LearningBank>> getAll(sqlite.SqliteReadContext database) async {
    final rows = await database.getAll('SELECT * FROM learning_bank ORDER BY id');
    return rows.map(LearningBankMapper.toDomain).toList(growable: false);
  }

  Future<LearningBankId> insert(
    sqlite.SqliteWriteContext transaction,
    CommitUid head,
  ) async {
    final row = LearningBankMapper.headToPersistence(head);
    final rows = await transaction.execute(
      'INSERT INTO learning_bank (head_commit_uid) VALUES (?) RETURNING id',
      [row['head_commit_uid']],
    );
    return LearningBankId(rows.single['id'] as int);
  }

  Future<void> setHead(
    sqlite.SqliteWriteContext transaction,
    LearningBankId id,
    CommitUid head,
  ) async {
    final row = LearningBankMapper.toPersistence(
      LearningBank(id: id, headCommitUid: head),
    );
    await transaction.execute(
      'UPDATE learning_bank SET head_commit_uid = ? WHERE id = ?',
      [row['head_commit_uid'], row['id']],
    );
  }

  Future<void> delete(sqlite.SqliteWriteContext transaction, LearningBankId id) async {
    await transaction.execute('DELETE FROM learning_bank WHERE id = ?', [id.value]);
  }
}
