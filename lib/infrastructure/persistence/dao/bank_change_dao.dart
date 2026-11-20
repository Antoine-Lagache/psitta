import 'dart:convert';

import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Persists a commit and its changes as one transaction-owned operation.
///
/// The caller owns the transaction so a commit can be saved atomically with
/// the corresponding learning-bank head and exercise-progress rows.
final class BankChangeDao {
  Future<void> insertCommit(
    sqlite.SqliteWriteContext transaction, {
    required BankCommit commit,
    required Iterable<BankChange> changes,
  }) async {
    final commitChanges = List<BankChange>.unmodifiable(changes);
    commit.validateChanges(commitChanges);

    await transaction.execute(
      '''
      INSERT INTO bank_commit (uid, parent_uid, is_frozen, format_version)
      VALUES (?, ?, ?, ?)
      ''',
      [
        commit.uid.value,
        commit.parentUid?.value,
        commit.isFrozen ? 1 : 0,
        commit.formatVersion,
      ],
    );

    for (final change in commitChanges) {
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
}
