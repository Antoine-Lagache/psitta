import '../identity/entity_id.dart';

/// A locally installed bank entry pointing at its current commit.
///
/// [id] is local to this user's database. The portable identity of the
/// represented bank state is [headCommitUid].
final class LearningBank {
  final LearningBankId id;
  final CommitUid headCommitUid;

  LearningBank({required this.id, required this.headCommitUid});
}
