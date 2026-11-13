import 'bank_change.dart';
import 'commit_uid.dart';

/// One node in a bank's single-parent commit chain.
///
/// A commit may be edited until it is frozen. Once frozen, changes are
/// immutable; further edits belong to a child commit.
final class BankCommit {
  final CommitUid uid;
  final CommitUid? parentUid;
  final bool isFrozen;

  BankCommit({required this.uid, required this.parentUid, required this.isFrozen}) {
    if (parentUid == uid) {
      throw ArgumentError('A commit cannot be its own parent');
    }
  }

  void ensureCanBeEdited() {
    if (isFrozen) {
      throw StateError('A frozen bank commit cannot be edited');
    }
  }

  void validateChanges(Iterable<BankChange> changes) {
    ensureCanBeEdited();
    final entities = <(String, String)>{};
    for (final change in changes) {
      if (change.ref.commitUid != uid) {
        throw ArgumentError('Every change must belong to this commit');
      }
      if (!entities.add((change.entityType, change.entityId))) {
        throw ArgumentError('A commit cannot change the same entity twice');
      }
    }
  }
}
