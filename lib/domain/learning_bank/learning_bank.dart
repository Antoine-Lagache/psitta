import 'commit_uid.dart';

/// A locally installed bank entry pointing at its current commit.
///
/// [id] is local to this user's database. The portable identity of the
/// represented bank state is [headCommitUid].
final class LearningBank {
  final int id;
  final CommitUid headCommitUid;

  LearningBank({required this.id, required this.headCommitUid}) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Must be a persisted local ID');
    }
  }
}
