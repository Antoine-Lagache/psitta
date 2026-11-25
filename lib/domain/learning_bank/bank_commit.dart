import '../identity/entity_id.dart';
import 'bank_change.dart';

/// One node in a bank's single-parent commit chain.
///
/// A commit may be edited until it is frozen. Once frozen, changes are
/// immutable; further edits belong to a child commit.
final class BankCommit {
  final CommitUid uid;
  final CommitUid? parentUid;
  final bool isFrozen;
  final int formatVersion;

  BankCommit({
    required this.uid,
    required this.parentUid,
    required this.isFrozen,
    this.formatVersion = 1,
  }) {
    if (formatVersion < 1) {
      throw ArgumentError.value(formatVersion, 'formatVersion', 'Must be positive');
    }
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
    final entities = <(String, String, String)>{};
    final changeIds = <int>{};
    for (final change in changes) {
      if (change.ref.commitUid != uid) {
        throw ArgumentError('Every change must belong to this commit');
      }
      if (!changeIds.add(change.ref.changeId)) {
        throw ArgumentError('A commit cannot contain duplicate change IDs');
      }
      if (!entities.add(change.entityIdentity)) {
        throw ArgumentError('A commit cannot contain two changes to one entity');
      }
    }
  }
}
