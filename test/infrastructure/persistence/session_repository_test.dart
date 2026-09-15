import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/sentence_group_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository exerciseRepository;
  late SessionRepository repository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    exerciseRepository = ExerciseRepository(database);
    repository = SessionRepository(database, exerciseRepository: exerciseRepository);
  });

  tearDown(() => testDatabase.dispose());

  Future<WordExercise> createWordExercise() async {
    final contentId = await testDatabase.insertContent();
    final exerciseId = await exerciseRepository.createWordExercise(contentId);
    return await exerciseRepository.getById(exerciseId) as WordExercise;
  }

  Session createWordSession(WordExercise exercise) {
    return Session(
      exercises: [exercise],
      sessionType: SessionType.wordSession,
      config: SRSConfig(),
    );
  }

  group('SessionRepository', () {
    test('round-trips an unfinished word session', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 10, 30);

      session.beginSession(startedAt);
      final sessionId = await repository.save(session);
      session.intermediateResult.id = sessionId;

      final activeResults = await repository.getAllActiveSessionResult();
      expect(activeResults, hasLength(1));
      expect(activeResults.single.id, sessionId);
      expect(activeResults.single.sessionType, SessionType.wordSession);
      expect(activeResults.single.startedAt?.toUtc(), startedAt);
      expect(activeResults.single.endAt, isNull);
      expect(activeResults.single.totalTimeSpent, Duration.zero);

      final restored = await repository.getActiveSession(
        activeResults.single,
        SRSConfig(),
      );
      final resume = restored.getResumeList().single;
      expect(resume.exerciseId, exercise.id);
      expect(resume.status, ExerciseStatus.newExercise);
      expect(resume.trainingCount, isNull);

      restored.resumeSession(startedAt.add(const Duration(minutes: 5)));
      expect(restored.currentExercise.id, exercise.id);
      expect(restored.currentExercise, isA<WordExercise>());
    });

    test('atomically persists answer progress and its resumable state', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 10);
      final answeredAt = startedAt.add(const Duration(minutes: 2));

      session.beginSession(startedAt);
      session.intermediateResult.id = await repository.save(session);
      final answeredExercise = session.currentExercise;
      session.submitAnswer(
        SubmittedExerciseAnswer(grade: Grade.again, answeredAt: answeredAt),
      );
      session.addTimeSpent(const Duration(minutes: 2));

      await repository.saveAnswerProgress(session, answeredExercise);

      expect(answeredExercise.newHistoryEntry, isEmpty);
      final persistedExercise = await exerciseRepository.getById(exercise.id);
      expect(persistedExercise, isA<WordExercise>());
      expect(persistedExercise!.status, ExerciseStatus.toReview);
      expect(persistedExercise.srsState.lastReview?.toUtc(), answeredAt);
      expect(persistedExercise.srsState.learningStepIndex, 0);

      final history = await ExerciseHistoryRepository(
        database,
      ).getList(exerciseId: exercise.id);
      expect(history, hasLength(1));
      expect(history.single.exerciseId, exercise.id);
      expect(history.single.grade, Grade.again);
      expect(history.single.status, ExerciseStatus.newExercise);
      expect(history.single.answeredAt.toUtc(), answeredAt);

      final activeResults = await repository.getAllActiveSessionResult();
      expect(activeResults, hasLength(1));
      expect(
        activeResults.single.getNumberOfAnswersByStatus(ExerciseStatus.newExercise),
        1,
      );
      expect(activeResults.single.totalTimeSpent, const Duration(minutes: 2));

      final restored = await repository.getActiveSession(
        activeResults.single,
        SRSConfig(),
      );
      final resume = restored.getResumeList().single;
      expect(resume.status, ExerciseStatus.learning);
      restored.resumeSession(answeredAt.add(const Duration(seconds: 30)));
      expect(restored.currentExercise.srsState.lastReview?.toUtc(), answeredAt);
    });

    test('final answer stores the result and removes the active snapshot', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 10);
      final answeredAt = startedAt.add(const Duration(minutes: 1));
      final endedAt = answeredAt.add(const Duration(seconds: 5));

      session.beginSession(startedAt);
      session.intermediateResult.id = await repository.save(session);
      final answeredExercise = session.currentExercise;
      session.submitAnswer(
        SubmittedExerciseAnswer(grade: Grade.easy, answeredAt: answeredAt),
      );
      session.addTimeSpent(endedAt.difference(startedAt));
      session.endSession(endedAt);

      await repository.saveAnswerProgress(session, answeredExercise);

      expect(await repository.getAllActiveSessionResult(), isEmpty);
      expect(await testDatabase.countRows('active_session_exercise'), 0);

      final results = await repository.getList();
      expect(results, hasLength(1));
      expect(results.single.id, session.intermediateResult.id);
      expect(results.single.endAt?.toUtc(), endedAt);
      expect(results.single.totalTimeSpent, endedAt.difference(startedAt));
      expect(results.single.numberOfUniqueExercisesCompleted, 1);
      expect(results.single.getNumberOfAnswersByStatus(ExerciseStatus.newExercise), 1);
      expect(
        await ExerciseHistoryRepository(database).getList(exerciseId: exercise.id),
        hasLength(1),
      );
    });

    test('restores sentence training status and remaining count', () async {
      final sentenceGroupRepository = SentenceGroupRepository(database);
      final groupId = await sentenceGroupRepository.createGroup();
      await sentenceGroupRepository.createInstance(
        groupId,
        await testDatabase.insertContent(),
      );
      await sentenceGroupRepository.createInstance(
        groupId,
        await testDatabase.insertContent(),
      );
      final exerciseId = await exerciseRepository.createSentenceExercise(groupId, 2);
      final exercise = await exerciseRepository.getById(exerciseId) as SentenceExercise;
      exercise.status = ExerciseStatus.consolidating;
      exercise.trainingCount = 1;
      final session = Session(
        exercises: [exercise],
        sessionType: SessionType.sentenceSession,
        config: SRSConfig(),
      );
      final startedAt = DateTime.utc(2026, 9, 5, 11);

      session.beginSession(startedAt);
      session.intermediateResult.id = await repository.save(session);

      final activeResult = (await repository.getAllActiveSessionResult()).single;
      final restored = await repository.getActiveSession(activeResult, SRSConfig());
      final resume = restored.getResumeList().single;
      expect(resume.exerciseId, exerciseId);
      expect(resume.status, ExerciseStatus.consolidating);
      expect(resume.trainingCount, 1);

      restored.resumeSession(startedAt.add(const Duration(minutes: 3)));
      final restoredExercise = restored.currentExercise as SentenceExercise;
      expect(restoredExercise.groupId, groupId);
      expect(restoredExercise.trainingCountMax, 2);
      expect(restoredExercise.trainingCount, 1);
      expect(restoredExercise.sentences.sentences, hasLength(2));
    });

    test('completeSession stores an early end and removes its snapshot', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 12);
      final endedAt = startedAt.add(const Duration(minutes: 4));

      session.beginSession(startedAt);
      session.intermediateResult.id = await repository.save(session);
      session.addTimeSpent(const Duration(minutes: 4));
      session.endSession(endedAt);

      await repository.completeSession(session);

      expect(await repository.getAllActiveSessionResult(), isEmpty);
      final persisted = (await repository.getList()).single;
      expect(persisted.endAt?.toUtc(), endedAt);
      expect(persisted.totalTimeSpent, const Duration(minutes: 4));
      expect(await testDatabase.countRows('active_session_exercise'), 0);
      expect(await testDatabase.countRows('exercise_history'), 0);
    });

    test('update replaces the result counts and resumable snapshot', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 12);

      session.beginSession(startedAt);
      session.intermediateResult.id = await repository.save(session);
      exercise.status = ExerciseStatus.learning;
      exercise.srsState = SRSState(
        interval: const Duration(minutes: 1),
        lastReview: startedAt,
        learningStepIndex: 0,
      );
      await exerciseRepository.save(exercise);
      session.intermediateResult.numberOfAnswersByStatus[ExerciseStatus
              .newExercise
              .index] =
          2;
      session.addTimeSpent(const Duration(minutes: 2));

      await repository.update(session);

      final activeResult = (await repository.getAllActiveSessionResult()).single;
      expect(activeResult.getNumberOfAnswersByStatus(ExerciseStatus.newExercise), 2);
      expect(activeResult.totalTimeSpent, const Duration(minutes: 2));
      final restored = await repository.getActiveSession(activeResult, SRSConfig());
      expect(restored.getResumeList().single.status, ExerciseStatus.learning);
      expect(await testDatabase.countRows('active_session_exercise'), 1);
    });

    test('deleteSessionResult cascades to counts and active snapshots', () async {
      final exercise = await createWordExercise();
      final session = createWordSession(exercise);
      session.beginSession(DateTime.utc(2026, 9, 5, 12));
      final sessionId = await repository.save(session);

      await repository.deleteSessionResult(sessionId);

      expect(await repository.getAllActiveSessionResult(), isEmpty);
      expect(await testDatabase.countRows('session_result'), 0);
      expect(await testDatabase.countRows('session_result_status_count'), 0);
      expect(await testDatabase.countRows('active_session_exercise'), 0);
    });

    test('getList applies a half-open date range and chronological order', () async {
      final exercise = await createWordExercise();
      final starts = [
        DateTime.utc(2026, 9, 5, 10),
        DateTime.utc(2026, 9, 5, 11),
        DateTime.utc(2026, 9, 5, 12),
      ];

      for (final startedAt in starts) {
        final session = createWordSession(exercise);
        session.beginSession(startedAt);
        session.intermediateResult.id = await repository.save(session);
        session.endSession(startedAt.add(const Duration(minutes: 1)));
        await repository.completeSession(session);
      }

      final results = await repository.getList(
        startedDate: starts.first,
        endDate: starts.last,
      );

      expect(results, hasLength(2));
      expect(
        results.map((result) => result.startedAt?.toUtc()),
        orderedEquals(starts.take(2)),
      );
    });

    test('getList can return only completed sessions', () async {
      final exercise = await createWordExercise();
      final active = createWordSession(exercise);
      final completed = createWordSession(exercise);
      final startedAt = DateTime.utc(2026, 9, 5, 10);

      active.beginSession(startedAt);
      active.intermediateResult.id = await repository.save(active);

      completed.beginSession(startedAt.add(const Duration(hours: 1)));
      completed.intermediateResult.id = await repository.save(completed);
      completed.endSession(startedAt.add(const Duration(hours: 1, minutes: 5)));
      await repository.completeSession(completed);

      final results = await repository.getList(completedOnly: true);

      expect(results, hasLength(1));
      expect(results.single.id, completed.intermediateResult.id);
    });

    test('allows multiple active sessions of the same type', () async {
      final firstExercise = await createWordExercise();
      final secondExercise = await createWordExercise();
      final startedAt = DateTime.utc(2026, 9, 5, 10);
      final first = createWordSession(firstExercise);
      final second = createWordSession(secondExercise);

      first.beginSession(startedAt);
      first.intermediateResult.id = await repository.save(first);
      second.beginSession(startedAt.add(const Duration(minutes: 1)));
      second.intermediateResult.id = await repository.save(second);

      final activeSessions = await repository.getAllActiveSessionResult();

      expect(activeSessions, hasLength(2));
      expect(
        activeSessions.map((session) => session.sessionType),
        everyElement(SessionType.wordSession),
      );
    });
  });
}
