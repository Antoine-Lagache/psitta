import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/infrastructure/persistence/mappers/bank_commit_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Reads and writes commit metadata. The caller controls write transactions.
final class BankCommitDao {
  Future<BankCommit?> getById(sqlite.SqliteReadContext database, CommitUid uid) async {
    final rows = await database.getAll('SELECT * FROM bank_commit WHERE uid = ?', [
      uid.value,
    ]);
    return rows.isEmpty ? null : BankCommitMapper.toDomain(rows.single);
  }

  /// Returns the head followed by its ancestors, including the root.
  Future<List<BankCommit>> getAncestry(
    sqlite.SqliteReadContext database,
    CommitUid head,
  ) async {
    final commits = <BankCommit>[];
    final seen = <CommitUid>{};
    CommitUid? uid = head;
    while (uid != null) {
      if (!seen.add(uid)) {
        throw StateError('Cycle in bank commit ancestry: $uid');
      }
      final commit = await getById(database, uid);
      if (commit == null) {
        throw StateError('Missing bank commit: $uid');
      }
      commits.add(commit);
      uid = commit.parentUid;
    }
    return List.unmodifiable(commits);
  }

  Future<void> insert(sqlite.SqliteWriteContext transaction, BankCommit commit) async {
    final row = BankCommitMapper.toPersistence(commit);
    await transaction.execute(
      '''
      INSERT INTO bank_commit (uid, parent_uid, is_frozen, format_version)
      VALUES (?, ?, ?, ?)
      ''',
      [row['uid'], row['parent_uid'], row['is_frozen'], row['format_version']],
    );
  }

  Future<void> freeze(sqlite.SqliteWriteContext transaction, CommitUid uid) async {
    await transaction.execute('UPDATE bank_commit SET is_frozen = 1 WHERE uid = ?', [
      uid.value,
    ]);
  }

  Future<void> delete(sqlite.SqliteWriteContext transaction, CommitUid uid) async {
    await transaction.execute('DELETE FROM bank_commit WHERE uid = ?', [uid.value]);
  }
}
