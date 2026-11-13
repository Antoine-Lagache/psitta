import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_change_ref.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/domain/learning_bank/commit_uid.dart';
import 'package:test/test.dart';

void main() {
  group('Learning bank domain validation', () {
    test('commit cannot be its own parent', () {
      final uid = CommitUid('commit-a');

      expect(
        () => BankCommit(uid: uid, parentUid: uid, isFrozen: false),
        throwsArgumentError,
      );
    });

    test('frozen commit cannot be edited', () {
      final commit = BankCommit(
        uid: CommitUid('commit-a'),
        parentUid: null,
        isFrozen: true,
      );

      expect(commit.ensureCanBeEdited, throwsStateError);
    });

    test('change reference cannot have a negative local ID', () {
      expect(
        () => BankChangeRef(commitUid: CommitUid('commit-a'), changeId: -1),
        throwsArgumentError,
      );
    });

    test('change cannot point to itself as its previous change', () {
      final ref = BankChangeRef(commitUid: CommitUid('commit-a'), changeId: 0);

      expect(
        () => BankChange(
          ref: ref,
          previousChangeRef: ref,
          changeType: 'update',
          payload: const {'entity': {'type': 'exercise', 'id': 'word-1'}},
        ),
        throwsArgumentError,
      );
    });

    test('change cannot point to another change in the same commit', () {
      final commitUid = CommitUid('commit-a');

      expect(
        () => BankChange(
          ref: BankChangeRef(commitUid: commitUid, changeId: 1),
          previousChangeRef: BankChangeRef(commitUid: commitUid, changeId: 0),
          changeType: 'update',
          payload: const {'entity': {'type': 'exercise', 'id': 'word-1'}},
        ),
        throwsArgumentError,
      );
    });

    test('change operation must not be blank', () {
      expect(
        () => BankChange(
          ref: BankChangeRef(commitUid: CommitUid('commit-a'), changeId: 0),
          previousChangeRef: null,
          changeType: '  ',
          payload: const {'entity': {'type': 'exercise', 'id': 'word-1'}},
        ),
        throwsArgumentError,
      );
    });

    test('change payload accepts only JSON-compatible values', () {
      expect(
        () => BankChange(
          ref: BankChangeRef(commitUid: CommitUid('commit-a'), changeId: 0),
          previousChangeRef: null,
          changeType: 'add',
          payload: {'invalid': Object()},
        ),
        throwsArgumentError,
      );
    });

    test('change payload must identify an entity with a type and ID', () {
      BankChange createChange(Map<String, Object?> payload) => BankChange(
        ref: BankChangeRef(commitUid: CommitUid('commit-a'), changeId: 0),
        previousChangeRef: null,
        changeType: 'add',
        payload: payload,
      );

      expect(() => createChange(const {}), throwsArgumentError);
      expect(() => createChange(const {'entity': {}}), throwsArgumentError);
      expect(
        () => createChange(const {'entity': {'type': 'exercise', 'id': ''}}),
        throwsArgumentError,
      );
    });

    test('commit cannot contain two changes to one entity', () {
      final uid = CommitUid('commit-a');
      final commit = BankCommit(uid: uid, parentUid: null, isFrozen: false);
      BankChange change(int changeId) => BankChange(
        ref: BankChangeRef(commitUid: uid, changeId: changeId),
        previousChangeRef: null,
        changeType: 'update',
        payload: const {'entity': {'type': 'exercise', 'id': 'word-1'}},
      );

      expect(
        () => commit.validateChanges([change(0), change(1)]),
        throwsArgumentError,
      );
    });

    test('commit changes must belong to that commit', () {
      final commit = BankCommit(
        uid: CommitUid('commit-a'),
        parentUid: null,
        isFrozen: false,
      );
      final change = BankChange(
        ref: BankChangeRef(commitUid: CommitUid('commit-b'), changeId: 0),
        previousChangeRef: null,
        changeType: 'add',
        payload: const {'entity': {'type': 'exercise', 'id': 'word-1'}},
      );

      expect(() => commit.validateChanges([change]), throwsArgumentError);
    });
  });
}
