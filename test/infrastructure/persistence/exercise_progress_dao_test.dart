import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';
import 'package:psitta/domain/learning_bank/bank_commit.dart';
import 'package:psitta/domain/srs/sentence_state.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_change_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_progress_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/learning_bank_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_instance_progress_dao.dart';
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase db;
  late LearningBankId bankId;
  late LearningBankId otherBankId;
  final uid = CommitUid('root');
  final exercise = ExerciseId((uid, 0));
  final progress = ExerciseProgressDao();
  final sentences = SentenceInstanceProgressDao();

  setUp(() async {
    db = await PersistenceTestDatabase.create();
    await db.database.writeTransaction((tx) async {
      await BankChangeDao().insertCommit(
        tx,
        commit: BankCommit(uid: uid, parentUid: null, isFrozen: true),
        changes: [
          BankChange(
            ref: BankChangeRef(commitUid: uid, changeId: 0),
            previousChangeRef: null,
            changeType: 'add exercise',
            payload: const {'exercise_id': 1},
          ),
        ],
      );
      bankId = await LearningBankDao().insert(tx, uid);
      otherBankId = await LearningBankDao().insert(tx, uid);
    });
  });

  tearDown(() => db.dispose());

  test('progression is scoped to the local bank and exact change', () async {
    final first = await db.database.writeTransaction(
      (tx) => progress.insert(tx, bankId, exercise),
    );
    final second = await db.database.writeTransaction(
      (tx) => progress.insert(tx, otherBankId, exercise),
    );
    expect(first, isNot(second));
    await db.database.readTransaction((tx) async {
      final entry = await progress.getById(tx, first);
      expect(entry?.id, first);
      expect(entry?.bankId, bankId);
      expect(entry?.exerciseId, exercise);
      expect((await progress.getByExercise(tx, bankId, exercise))?.id, first);
      expect((await progress.getByBank(tx, otherBankId)).single.id, second);
      expect(await progress.getById(tx, ExerciseProgressId(999)), isNull);
    });
    await expectLater(
      db.database.writeTransaction((tx) => progress.insert(tx, bankId, exercise)),
      throwsA(anything),
    );
    expect(await db.countRows('exercise_progress'), 2);
  });

  test('sentence states round trip, update and cascade independently', () async {
    final first = await db.database.writeTransaction(
      (tx) => progress.insert(tx, bankId, exercise),
    );
    final second = await db.database.writeTransaction(
      (tx) => progress.insert(tx, otherBankId, exercise),
    );
    final id = SentenceInstanceProgressId((first, 12));
    final other = SentenceInstanceProgressId((second, 12));
    final extra = SentenceInstanceProgressId((first, 13));
    await db.database.writeTransaction((tx) async {
      await sentences.upsert(tx, id, SentenceState());
      await sentences.upsert(tx, other, SentenceState(shownCount: 1));
      await sentences.upsert(tx, extra, SentenceState());
      await sentences.upsert(
        tx,
        id,
        SentenceState(shownCount: 4, accumulatedScore: 2.5, isInLearning: true),
      );
    });
    await db.database.readTransaction((tx) async {
      final entry = (await sentences.getById(tx, id))!;
      expect(entry.id, id);
      expect(entry.state.shownCount, 4);
      expect(entry.state.accumulatedScore, 2.5);
      expect(entry.state.isInLearning, isTrue);
      expect((await sentences.getById(tx, other))?.state.shownCount, 1);
      expect((await sentences.getByExercise(tx, first)).map((e) => e.id), [id, extra]);
    });
    await db.database.writeTransaction((tx) async {
      await sentences.delete(tx, extra);
      await progress.delete(tx, first);
    });
    await db.database.readTransaction((tx) async {
      expect(await sentences.getByExercise(tx, first), isEmpty);
      expect(await sentences.getById(tx, other), isNotNull);
    });
    expect(await db.database.getAll('PRAGMA foreign_key_check'), isEmpty);
  });
}
