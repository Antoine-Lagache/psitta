import 'commit_uid.dart';

/// One node in a bank's single-parent commit chain.
///
/// A commit may be edited until it is frozen. Once frozen, changes are
/// immutable; further edits belong to a child commit.
final class BankCommit {
  final CommitUid uid;
  final CommitUid? parentUid;
  final bool isFrozen;

  BankCommit({
    required this.uid,
    required this.parentUid,
    required this.isFrozen,
  }) {
    if (parentUid == uid) {
      throw ArgumentError('A commit cannot be its own parent');
    }
  }
}
