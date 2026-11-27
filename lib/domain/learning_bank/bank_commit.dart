import '../identity/entity_id.dart';
import 'bank_change.dart';
import 'bank_entity_identity.dart';

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
    final entities = <BankEntityIdentity<Object?>, List<BankChange>>{};
    final changeIds = <int>{};
    for (final change in changes) {
      if (change.ref.commitUid != uid) {
        throw ArgumentError('Every change must belong to this commit');
      }
      if (!changeIds.add(change.ref.changeId)) {
        throw ArgumentError('A commit cannot contain duplicate change IDs');
      }
      entities.putIfAbsent(change.getEntityIdentity(), () => []).add(change);
    }
    for (final entityChanges in entities.values) {
      if (entityChanges.length == 1) continue;
      entityChanges.sort((a, b) => a.ref.changeId.compareTo(b.ref.changeId));
      if (entityChanges.length != 2 ||
          !entityChanges.first.changeType.startsWith('remove ') ||
          !entityChanges.last.changeType.startsWith('add ')) {
        throw ArgumentError('Only removal followed by addition may share an entity ID');
      }
    }
  }
}
