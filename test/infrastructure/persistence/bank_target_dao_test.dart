import 'dart:io';

import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_exercise_history_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_session_exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_session_result_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/srs_state_dao.dart';
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase db;
  final bank = LearningBankId(1);
  final uid = CommitUid('root');
  final exercise = ExerciseProgressId(1);
  final srs = SrsStateDao();
  final history = BankExerciseHistoryDao();
  final sessions = BankSessionResultDao();
  final snapshots = BankSessionExerciseDao();

  setUp(() async {
    db = await PersistenceTestDatabase.create(migrate: false);
    final schema = File('docs/architecture/database_schema_v0.3.sql').readAsStringSync();
    await db.database.writeTransaction((tx) async {
      for (final statement in schema.split(';')) {
        if (statement.trim().isNotEmpty) await tx.execute(statement);
      }
      await tx.execute("INSERT INTO bank_commit (uid) VALUES ('root')");
      await tx.execute('''
        INSERT INTO bank_change (commit_uid, change_id, change_type, payload_json)
        VALUES ('root', 0, 'add exercise',
          '{"exercise_id": 7, "exercise_type": "word", "priority_order": 3}'),
          ('root', 1, 'add sentence', '{"sentence_id": 4}')
        ''');
      await tx.execute("INSERT INTO learning_bank VALUES (1, 'root')");
      await tx.execute("INSERT INTO exercise_progress VALUES (1, 1, 'root', 0)");
    });
  });

  tearDown(() => db.dispose());

  test('FSRS insert, update, selection and counts use local progression', () async {
    await db.database.writeTransaction((tx) async {
      await srs.insert(tx, exercise, SRSState(exerciseId: exercise));
    });
    await db.database.readTransaction((tx) async {
      expect((await srs.getById(tx, exercise))?.exerciseId, exercise);
      expect(await srs.getNewExercises(tx, bank, 10, 'word'), [exercise]);
      expect(await srs.countNewExercises(tx, bank, null), 1);
      expect(await srs.countDueExercises(tx, bank, 100, null), 0);
    });
    await db.database.writeTransaction((tx) async {
      await srs.update(
        tx,
        exercise,
        SRSState(
          exerciseId: exercise,
          lastReview: DateTime.utc(2026),
          due: DateTime.utc(2026, 1, 2),
          stability: 31,
          difficulty: 5,
        ),
      );
    });
    await db.database.readTransaction((tx) async {
      final now = DateTime.utc(2026, 1, 3).microsecondsSinceEpoch;
      expect(await srs.getDueExercises(tx, bank, now, 10, 'word'), [exercise]);
      expect(await srs.countDueExercises(tx, bank, now, 'word'), 1);
      expect(await srs.countNewExercises(tx, bank, null), 0);
      expect((await srs.countProgressByType(tx, bank))['word']?.mastered, 1);
    });
  });

  test('history preserves exact sentence reference and supports deletion', () async {
    final entry = (
      id: null,
      exerciseId: exercise,
      sentenceId: SentenceId((uid, 1)),
      grade: Grade.good,
      answeredAt: DateTime.utc(2026),
      status: ExerciseStatus.learning,
    );
    final id = await db.database.writeTransaction((tx) => history.insert(tx, entry));
    await db.database.writeTransaction((tx) => history.insertAll(tx, [entry]));
    await db.database.readTransaction((tx) async {
      expect((await history.getById(tx, id))?.sentenceId, entry.sentenceId);
      expect(await history.hasHistory(tx, exercise), isTrue);
      expect(await history.getList(tx, exerciseId: exercise), hasLength(2));
    });
    await db.database.writeTransaction((tx) async {
      await history.delete(tx, id);
      await history.deleteAll(tx, exercise);
    });
    expect(await db.countRows('exercise_history'), 0);
  });

  test('session aggregates and resumable snapshots use target foreign keys', () async {
    final result = SessionResult(sessionType: SessionType.wordSession);
    result.startedAt = DateTime.utc(2026);
    final id = await db.database.writeTransaction((tx) async {
      final id = await sessions.insert(tx, bank, uid, result);
      await snapshots.insertAll(tx, id, [
        ExerciseResume(exerciseId: exercise, status: ExerciseStatus.newExercise),
      ]);
      return id;
    });
    await db.database.readTransaction((tx) async {
      expect((await sessions.getById(tx, id))?.bankId, bank);
      expect((await sessions.getById(tx, id))?.commitUid, uid);
      expect((await snapshots.getAll(tx, id)).single.exerciseId, exercise);
      expect(await snapshots.getAllSessionId(tx), [id]);
      expect((await snapshots.countByStatus(tx, id)).single.exerciseCount, 1);
    });
    result.id = id;
    result.endAt = DateTime.utc(2026, 1, 2);
    result.numberOfUniqueExercisesCompleted = 1;
    await db.database.writeTransaction((tx) async {
      await sessions.update(tx, result);
      await snapshots.deleteAll(tx, id);
    });
    await db.database.readTransaction((tx) async {
      final completed = await sessions.getList(tx, completedOnly: true);
      expect(completed.single.result.numberOfUniqueExercisesCompleted, 1);
      expect(await snapshots.getAll(tx, id), isEmpty);
    });
    await db.database.writeTransaction((tx) => sessions.delete(tx, id));
    expect(await db.countRows('session_result'), 0);
    expect(await db.database.getAll('PRAGMA foreign_key_check'), isEmpty);
  });
}
