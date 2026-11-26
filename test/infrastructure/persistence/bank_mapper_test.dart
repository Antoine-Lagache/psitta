import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/domain/learning_bank/learning_bank.dart';
import 'package:psitta/infrastructure/persistence/mappers/bank_change_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/bank_commit_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/learning_bank_mapper.dart';
import 'package:test/test.dart';

void main() {
  test('commit mapper preserves parent, frozen state and format', () {
    final commit = BankCommit(
      uid: CommitUid('child'),
      parentUid: CommitUid('root'),
      isFrozen: true,
      formatVersion: 1,
    );
    final row = BankCommitMapper.toPersistence(commit);
    expect(row['is_frozen'], 1);
    final loaded = BankCommitMapper.toDomain(row);
    expect(loaded.uid, commit.uid);
    expect(loaded.parentUid, commit.parentUid);
    expect(loaded.isFrozen, commit.isFrozen);
    expect(loaded.formatVersion, commit.formatVersion);
  });

  test('change mapper preserves nested payload and composite references', () {
    final change = BankChange(
      ref: BankChangeRef(commitUid: CommitUid('child'), changeId: 2),
      previousChangeRef: BankChangeRef(commitUid: CommitUid('root'), changeId: 0),
      changeType: 'add exercise',
      payload: {
        'exercise_id': 42,
        'content_ref': {'commit_uid': 'root', 'change_id': 1},
      },
    );
    final row = BankChangeMapper.toPersistence(change);
    expect(row['payload_json'], isA<String>());
    final loaded = BankChangeMapper.toDomain(row);
    expect(loaded.ref, change.ref);
    expect(loaded.previousChangeRef, change.previousChangeRef);
    expect(loaded.changeType, change.changeType);
    expect(loaded.payload, change.payload);
    expect(
      () => BankChangeMapper.toDomain({...row, 'previous_change_id': null}),
      throwsStateError,
    );
  });

  test('learning bank mapper preserves the local ID and active commit', () {
    final bank = LearningBank(id: LearningBankId(1), headCommitUid: CommitUid('root'));
    final row = LearningBankMapper.toPersistence(bank);
    expect(row, {'id': 1, 'head_commit_uid': 'root'});
    final loaded = LearningBankMapper.toDomain(row);
    expect(loaded.id, bank.id);
    expect(loaded.headCommitUid, bank.headCommitUid);
    expect(LearningBankMapper.headToPersistence(bank.headCommitUid), {
      'head_commit_uid': 'root',
    });
  });
}
