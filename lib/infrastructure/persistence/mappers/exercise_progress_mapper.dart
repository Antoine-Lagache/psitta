import 'package:psitta/domain/identity/entity_id.dart';

/// Local progression identity and the exact editorial snapshot it follows.
typedef ExerciseProgressReference = ({
  ExerciseProgressId id,
  LearningBankId bankId,
  ExerciseId exerciseId,
});

class ExerciseProgressMapper {
  const ExerciseProgressMapper();

  static ExerciseProgressReference toDomain(Map<String, Object?> row) => (
    id: ExerciseProgressId(row['id'] as int),
    bankId: LearningBankId(row['learning_bank_id'] as int),
    exerciseId: ExerciseId((
      CommitUid(row['active_commit_uid'] as String),
      row['active_change_id'] as int,
    )),
  );

  static Map<String, Object?> toPersistence(
    LearningBankId bankId,
    ExerciseId exerciseId,
  ) => {
    'learning_bank_id': bankId.value,
    'active_commit_uid': exerciseId.commitUid.value,
    'active_change_id': exerciseId.changeId,
  };
}
