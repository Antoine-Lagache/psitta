import 'commit_uid.dart';

/// Composite identity of a change within its commit.
final class BankChangeRef {
  final CommitUid commitUid;
  final int changeId;

  BankChangeRef({required this.commitUid, required this.changeId}) {
    if (changeId < 0) {
      throw ArgumentError.value(changeId, 'changeId', 'Must not be negative');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BankChangeRef &&
      other.commitUid == commitUid &&
      other.changeId == changeId;

  @override
  int get hashCode => Object.hash(commitUid, changeId);

  @override
  String toString() => '($commitUid, $changeId)';
}
