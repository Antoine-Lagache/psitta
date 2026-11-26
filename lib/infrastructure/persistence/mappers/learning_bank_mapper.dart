import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/learning_bank.dart';

/// Translates installed bank rows and their typed identifiers.
class LearningBankMapper {
  const LearningBankMapper();

  static Map<String, Object?> toPersistence(LearningBank domain) => {
    'id': domain.id.value,
    'head_commit_uid': domain.headCommitUid.value,
  };

  static Map<String, Object?> headToPersistence(CommitUid head) => {
    'head_commit_uid': head.value,
  };

  static LearningBank toDomain(Map<String, Object?> row) => LearningBank(
    id: LearningBankId(row['id'] as int),
    headCommitUid: CommitUid(row['head_commit_uid'] as String),
  );
}
