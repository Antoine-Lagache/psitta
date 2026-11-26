import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_change_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/learning_bank_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/legacy_bank_content_mapper.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// Builds the official bank from a clean release corpus, not a user database.
final class BundledBankBuilder {
  Future<CommitUid> build(sqlite.SqliteDatabase database) {
    return database.writeTransaction((tx) async {
      // A staging UID is never persisted. The release identity covers the
      // ordered snapshots, including metadata and media references.
      Future<({BankCommit commit, List<BankChange> changes})> map(CommitUid uid) {
        return const LegacyBankContentMapper().mapRootCommit(
          tx,
          commitUid: uid,
          sourceLanguage: 'en',
          targetLanguage: 'ja',
          description: 'Japanese vocabulary, sentences and kana.',
          defaultSettings: const {
            'sessions.characters.enabled': true,
            'sessions.characters.new_count': 5,
            'sessions.reviews.max_count.v2': -1,
            'sessions.sentences.new_count': 3,
            'sessions.words.new_count': 4,
          },
        );
      }

      final staging = await map(CommitUid('staging'));
      final serialized = jsonEncode({
        'format_version': staging.commit.formatVersion,
        'changes': [
          for (final change in staging.changes)
            {
              'change_id': change.ref.changeId,
              'change_type': change.changeType,
              'payload': change.payload,
            },
        ],
      });
      final digest = sha256.convert(utf8.encode(serialized));
      final uid = CommitUid('psitta-root-$digest');
      final root = await map(uid);
      await BankChangeDao().insertCommit(tx, commit: root.commit, changes: root.changes);
      await LearningBankDao().insert(tx, uid);
      return uid;
    });
  }
}
