import 'dart:convert';

import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

import 'bank_commit_dao.dart';

/// Stores change snapshots without resolving their editorial history.
final class BankChangeDao {
  Future<BankChange?> getById(
    sqlite.SqliteReadContext database,
    BankChangeRef ref,
  ) async {
    final rows = await database.getAll(
      'SELECT * FROM bank_change WHERE commit_uid = ? AND change_id = ?',
      [ref.commitUid.value, ref.changeId],
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  Future<List<BankChange>> getByCommit(
    sqlite.SqliteReadContext database,
    CommitUid uid,
  ) async {
    final rows = await database.getAll(
      'SELECT * FROM bank_change WHERE commit_uid = ? ORDER BY change_id',
      [uid.value],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// Inserts a complete new commit, including frozen snapshots.
  /// The caller owns the transaction.
  Future<void> insertCommit(
    sqlite.SqliteWriteContext transaction, {
    required BankCommit commit,
    required Iterable<BankChange> changes,
  }) async {
    final commitChanges = List<BankChange>.unmodifiable(changes);
    commit.validateChanges(commitChanges);
    await BankCommitDao().insert(transaction, commit);
    await _insertAll(transaction, commitChanges);
  }

  /// Adds changes to an existing draft, validating the combined snapshot.
  Future<void> insertAll(
    sqlite.SqliteWriteContext transaction,
    CommitUid uid,
    Iterable<BankChange> changes,
  ) async {
    final commit = await BankCommitDao().getById(transaction, uid);
    if (commit == null) throw StateError('Missing bank commit: $uid');
    commit.ensureCanBeEdited();
    final additions = List<BankChange>.of(changes);
    commit.validateChanges([...await getByCommit(transaction, uid), ...additions]);
    await _insertAll(transaction, additions);
  }

  Future<void> delete(
    sqlite.SqliteWriteContext transaction,
    BankChangeRef ref,
  ) async {
    final commit = await BankCommitDao().getById(transaction, ref.commitUid);
    if (commit == null) throw StateError('Missing bank commit: ${ref.commitUid}');
    commit.ensureCanBeEdited();
    await transaction.execute(
      'DELETE FROM bank_change WHERE commit_uid = ? AND change_id = ?',
      [ref.commitUid.value, ref.changeId],
    );
  }

  Future<void> _insertAll(
    sqlite.SqliteWriteContext transaction,
    Iterable<BankChange> changes,
  ) async {
    for (final change in changes) {
      await transaction.execute(
        '''
        INSERT INTO bank_change (
          commit_uid,
          change_id,
          previous_commit_uid,
          previous_change_id,
          change_type,
          payload_json
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          change.ref.commitUid.value,
          change.ref.changeId,
          change.previousChangeRef?.commitUid.value,
          change.previousChangeRef?.changeId,
          change.changeType,
          jsonEncode(change.payload),
        ],
      );
    }
  }

  static BankChange _fromRow(Map<String, Object?> row) {
    final previousUid = row['previous_commit_uid'] as String?;
    final previousId = row['previous_change_id'] as int?;
    if ((previousUid == null) != (previousId == null)) {
      throw StateError('Incomplete previous change reference');
    }
    return BankChange(
      ref: BankChangeRef(
        commitUid: CommitUid(row['commit_uid'] as String),
        changeId: row['change_id'] as int,
      ),
      previousChangeRef: previousUid == null
          ? null
          : BankChangeRef(commitUid: CommitUid(previousUid), changeId: previousId!),
      changeType: row['change_type'] as String,
      payload: jsonDecode(row['payload_json'] as String) as Map<String, Object?>,
    );
  }
}
