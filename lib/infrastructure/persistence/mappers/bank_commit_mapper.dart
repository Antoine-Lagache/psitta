import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';

/// Translates commit metadata between SQLite values and the domain.
class BankCommitMapper {
  const BankCommitMapper();

  static Map<String, Object?> toPersistence(BankCommit domain) => {
    'uid': domain.uid.value,
    'parent_uid': domain.parentUid?.value,
    'is_frozen': domain.isFrozen ? 1 : 0,
    'format_version': domain.formatVersion,
  };

  static BankCommit toDomain(Map<String, Object?> row) {
    final parent = row['parent_uid'] as String?;
    return BankCommit(
      uid: CommitUid(row['uid'] as String),
      parentUid: parent == null ? null : CommitUid(parent),
      isFrozen: row['is_frozen'] == 1,
      formatVersion: row['format_version'] as int,
    );
  }
}
