import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_change_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_commit_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/learning_bank_dao.dart';
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase db;
  final commits = BankCommitDao();
  final changes = BankChangeDao();
  final banks = LearningBankDao();
  final root = CommitUid('root');
  final child = CommitUid('child');

  BankChange setting(CommitUid uid, int id, {BankChangeRef? previous}) => BankChange(
    ref: BankChangeRef(commitUid: uid, changeId: id),
    previousChangeRef: previous,
    changeType: previous == null ? 'add setting' : 'update setting',
    payload: {'profile': 'default', 'key': 'limit', 'value': id},
  );

  setUp(() async {
    db = await PersistenceTestDatabase.create();
  });
  tearDown(() => db.dispose());

  test('commit ancestry, change references and local bank head round trip', () async {
    final original = setting(root, 0);
    final updated = setting(child, 1, previous: original.ref);
    final bankId = await db.database.writeTransaction((tx) async {
      await changes.insertCommit(
        tx,
        commit: BankCommit(uid: root, parentUid: null, isFrozen: true),
        changes: [original],
      );
      await changes.insertCommit(
        tx,
        commit: BankCommit(uid: child, parentUid: root, isFrozen: false),
        changes: [updated],
      );
      return banks.insert(tx, root);
    });

    await db.database.readTransaction((tx) async {
      expect((await banks.getById(tx, bankId))?.headCommitUid, root);
      expect((await banks.getAll(tx)).single.id, bankId);
      final ancestry = await commits.getAncestry(tx, child);
      expect(ancestry.map((commit) => commit.uid), [child, root]);
      expect(ancestry.last.isFrozen, isTrue);
      final loaded = await changes.getById(tx, updated.ref);
      expect(loaded?.previousChangeRef, original.ref);
      expect(loaded?.payload, updated.payload);
      expect((await changes.getByCommit(tx, root)).single.ref, original.ref);
      expect(await commits.getById(tx, CommitUid('missing')), isNull);
      expect(
        await changes.getById(tx, BankChangeRef(commitUid: root, changeId: 99)),
        isNull,
      );
    });

    await db.database.writeTransaction((tx) async {
      await banks.setHead(tx, bankId, child);
      await commits.freeze(tx, child);
    });
    await db.database.readTransaction((tx) async {
      expect((await banks.getById(tx, bankId))?.headCommitUid, child);
      expect((await commits.getById(tx, child))?.isFrozen, isTrue);
    });
  });

  test('draft changes reject duplicate identities and frozen edits', () async {
    await db.database.writeTransaction((tx) async {
      await commits.insert(tx, BankCommit(uid: root, parentUid: null, isFrozen: false));
      await changes.insertAll(tx, root, [setting(root, 0)]);
    });
    await expectLater(
      db.database.writeTransaction(
        (tx) => changes.insertAll(tx, root, [setting(root, 1)]),
      ),
      throwsArgumentError,
    );
    await db.database.writeTransaction((tx) async {
      await changes.delete(tx, setting(root, 0).ref);
      await changes.insertAll(tx, root, [setting(root, 1)]);
      await commits.freeze(tx, root);
    });
    await expectLater(
      db.database.writeTransaction((tx) => changes.delete(tx, setting(root, 1).ref)),
      throwsStateError,
    );
    await expectLater(
      db.database.writeTransaction(
        (tx) => changes.insertAll(tx, root, [setting(root, 2)]),
      ),
      throwsStateError,
    );
    expect(await db.countRows('bank_change'), 1);
  });
}
