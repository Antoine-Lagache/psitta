import 'dart:async';

import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/application/models/session/start_session_result.dart';
import 'package:psitta/application/models/session/submit_answer_result.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import '../../infrastructure/persistence/support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late ExerciseRepository exerciseRepository;
  late SessionRepository sessionRepository;
  late DateTime now;
  late Duration elapsed;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    exerciseRepository = ExerciseRepository(database);
    sessionRepository = SessionRepository(
      database,
      exerciseRepository: exerciseRepository,
    );
    now = DateTime.utc(2026, 9, 14, 10);
    elapsed = Duration.zero;
  });

  tearDown(() => testDatabase.dispose());

  SessionController createController({
    SessionRepository? sessions,
    DateTime Function()? clock,
    Duration Function()? elapsedClock,
  }) {
    return SessionController(
      sessionRepository: sessions ?? sessionRepository,
      exerciseRepository: exerciseRepository,
      contentController: ContentController(
        contentRepository: ContentRepository(database),
        mediaRepository: MediaRepository(database),
      ),
      config: SRSConfig(newCount: 10, reviewCount: 10),
      now: clock ?? () => now,
      elapsedNow: elapsedClock ?? () => elapsed,
    );
  }

  Future<int> createWordExercise() async {
    final contentId = await testDatabase.insertContent();
    return exerciseRepository.createWordExercise(contentId);
  }

  SessionOverview overviewOf(
    List<SessionOverview> overviews,
    SessionType sessionType,
  ) {
    return overviews.singleWhere(
      (overview) => overview.sessionType == sessionType,
    );
  }

  group('SessionController', () {
    test('does not persist an empty session', () async {
      final controller = createController();

      final result = await controller.startNewSession(SessionType.wordSession);

      expect(result, StartSessionResult.noExerciseAvailable);
      expect(controller.hasActiveSession, isFalse);
      expect(await testDatabase.countRows('session_result'), 0);
    });

    test(
      'builds limited overviews for new sessions with one timestamp',
      () async {
        final exerciseIds = <int>[];
        for (var index = 0; index < 12; index++) {
          exerciseIds.add(await createWordExercise());
        }

        final dueExercise =
            await exerciseRepository.getById(exerciseIds.first) as WordExercise;
        dueExercise.srsState = SRSState(
          interval: const Duration(days: 1),
          lastReview: now.subtract(const Duration(days: 2)),
          learningStepIndex: -1,
        );
        dueExercise.newHistoryEntry.add(
          ExerciseHistoryEntry(
            exerciseId: dueExercise.id,
            grade: Grade.good,
            answeredAt: now.subtract(const Duration(days: 2)),
            status: ExerciseStatus.newExercise,
          ),
        );
        await exerciseRepository.save(dueExercise);

        var clockCalls = 0;
        final controller = createController(
          clock: () {
            clockCalls++;
            return now;
          },
        );

        final overviews = await controller.getSessionOverviews();
        final wordOverview = overviewOf(overviews, SessionType.wordSession);
        final sentenceOverview = overviewOf(
          overviews,
          SessionType.sentenceSession,
        );

        expect(overviews, hasLength(SessionType.values.length));
        expect(wordOverview.hasActiveSession, isFalse);
        expect(wordOverview.newExerciseCount, 10);
        expect(wordOverview.reviewExerciseCount, 1);
        expect(sentenceOverview.hasActiveSession, isFalse);
        expect(sentenceOverview.newExerciseCount, 0);
        expect(sentenceOverview.reviewExerciseCount, 0);
        expect(clockCalls, 1);
        expect(() => overviews.add(wordOverview), throwsUnsupportedError);
      },
    );

    test('builds an active overview from resumable exercise statuses', () async {
      final statuses = [
        ExerciseStatus.newExercise,
        ExerciseStatus.toReview,
        ExerciseStatus.learning,
        ExerciseStatus.relearning,
        ExerciseStatus.completed,
      ];
      final exercises = <WordExercise>[];

      for (final status in statuses) {
        final exerciseId = await createWordExercise();
        final exercise =
            await exerciseRepository.getById(exerciseId) as WordExercise;
        exercise.status = status;
        if (status == ExerciseStatus.learning ||
            status == ExerciseStatus.relearning) {
          exercise.srsState = SRSState(
            interval: const Duration(minutes: 1),
            lastReview: now,
            learningStepIndex: 0,
          );
        }
        exercises.add(exercise);
      }

      final session = Session(
        exercises: exercises,
        sessionType: SessionType.wordSession,
        config: SRSConfig(),
      );
      session.beginSession(now);
      session.intermediateResult.id = await sessionRepository.save(session);

      final wordOverview = overviewOf(
        await createController().getSessionOverviews(),
        SessionType.wordSession,
      );

      expect(wordOverview.hasActiveSession, isTrue);
      expect(wordOverview.newExerciseCount, 1);
      expect(wordOverview.reviewExerciseCount, 3);
    });

    test(
      'starts a session and previews every allowed grade with one timestamp',
      () async {
        await createWordExercise();
        var clockCalls = 0;
        final controller = createController(
          clock: () {
            clockCalls++;
            return now;
          },
        );

        expect(
          await controller.startNewSession(SessionType.wordSession),
          StartSessionResult.started,
        );
        expect(controller.hasActiveSession, isTrue);
        expect((await controller.getCurrentExerciseContent()).id, isNotNull);

        clockCalls = 0;
        final intervals = controller.getCurrentExercisePreviewIntervals();

        expect(intervals.keys, unorderedEquals(Grade.values));
        expect(clockCalls, 1);
        expect(() => intervals[Grade.again] = Duration.zero, throwsUnsupportedError);
      },
    );

    test('blocks a new session when one of the same type is persisted', () async {
      await createWordExercise();
      final firstController = createController();
      expect(
        await firstController.startNewSession(SessionType.wordSession),
        StartSessionResult.started,
      );
      await firstController.pauseSession();

      final secondController = createController();
      final result = await secondController.startNewSession(SessionType.wordSession);

      expect(result, StartSessionResult.activeSessionAlreadyExists);
      expect(secondController.hasActiveSession, isFalse);
    });

    test('does not block a new session because another type is persisted', () async {
      await createWordExercise();
      final firstController = createController();
      expect(
        await firstController.startNewSession(SessionType.wordSession),
        StartSessionResult.started,
      );
      await firstController.pauseSession();

      final secondController = createController();
      final result = await secondController.startNewSession(SessionType.sentenceSession);

      expect(result, StartSessionResult.noExerciseAvailable);
      expect(secondController.hasActiveSession, isFalse);
    });

    test('does not publish a session when its initial save fails', () async {
      await createWordExercise();
      final controller = createController();
      await database.execute('''
        CREATE TRIGGER fail_session_insert
        BEFORE INSERT ON session_result
        BEGIN
          SELECT RAISE(ABORT, 'forced failure');
        END;
      ''');

      await expectLater(
        controller.startNewSession(SessionType.wordSession),
        throwsA(anything),
      );

      expect(controller.hasActiveSession, isFalse);
      expect(await testDatabase.countRows('session_result'), 0);
    });

    test('returns whether an answer advances or completes the session', () async {
      await createWordExercise();
      final controller = createController();
      await controller.startNewSession(SessionType.wordSession);

      now = now.add(const Duration(minutes: 2));
      elapsed += const Duration(minutes: 2);
      expect(await controller.submitAnswer(Grade.again), SubmitAnswerResult.nextExercise);
      expect(controller.hasActiveSession, isTrue);
      expect(
        (await sessionRepository.getAllActiveSessionResult()).single.totalTimeSpent,
        const Duration(minutes: 2),
      );

      now = now.add(const Duration(minutes: 1));
      elapsed += const Duration(minutes: 1);
      expect(
        await controller.submitAnswer(Grade.easy),
        SubmitAnswerResult.sessionCompleted,
      );
      expect(controller.hasActiveSession, isFalse);
      expect(
        (await sessionRepository.getList(completedOnly: true)).single.totalTimeSpent,
        const Duration(minutes: 3),
      );
    });

    test('accumulates segments across a pause and resume', () async {
      await createWordExercise();
      final firstController = createController();
      await firstController.startNewSession(SessionType.wordSession);

      now = now.add(const Duration(minutes: 5));
      elapsed += const Duration(minutes: 5);
      await firstController.pauseSession();

      var persisted = (await sessionRepository.getAllActiveSessionResult()).single;
      expect(persisted.totalTimeSpent, const Duration(minutes: 5));

      now = now.add(const Duration(hours: 1));
      elapsed += const Duration(hours: 1);
      final secondController = createController();
      expect(await secondController.resumeActiveSession(SessionType.wordSession), isTrue);

      now = now.add(const Duration(minutes: 3));
      elapsed += const Duration(minutes: 3);
      await secondController.pauseSession();

      persisted = (await sessionRepository.getAllActiveSessionResult()).single;
      expect(persisted.totalTimeSpent, const Duration(minutes: 8));
    });

    test('persists the current segment when ending early', () async {
      await createWordExercise();
      final controller = createController();
      await controller.startNewSession(SessionType.wordSession);

      now = now.add(const Duration(minutes: 4));
      elapsed += const Duration(minutes: 4);
      await controller.endSession();

      final completed = (await sessionRepository.getList(completedOnly: true)).single;
      expect(completed.totalTimeSpent, const Duration(minutes: 4));
      expect(controller.hasActiveSession, isFalse);
    });

    test('invalidates memory and preserves the snapshot after a write failure', () async {
      final exerciseId = await createWordExercise();
      final controller = createController();
      await controller.startNewSession(SessionType.wordSession);
      await database.execute('''
        CREATE TRIGGER fail_srs_update
        BEFORE UPDATE ON srs_state
        BEGIN
          SELECT RAISE(ABORT, 'forced failure');
        END;
      ''');

      now = now.add(const Duration(minutes: 1));
      elapsed += const Duration(minutes: 1);
      await expectLater(controller.submitAnswer(Grade.again), throwsA(anything));

      expect(controller.hasActiveSession, isFalse);
      final overview = overviewOf(
        await controller.getSessionOverviews(),
        SessionType.wordSession,
      );
      expect(overview.hasActiveSession, isTrue);
      expect(
        (await sessionRepository.getAllActiveSessionResult()).single.totalTimeSpent,
        Duration.zero,
      );
      expect(
        await ExerciseHistoryRepository(database).getList(exerciseId: exerciseId),
        isEmpty,
      );

      await database.execute('DROP TRIGGER fail_srs_update');
      expect(await controller.resumeActiveSession(SessionType.wordSession), isTrue);
    });

    test('rejects a concurrent mutating operation', () async {
      final blockingRepository = _BlockingSessionRepository(
        database,
        exerciseRepository: exerciseRepository,
      );
      final controller = createController(sessions: blockingRepository);

      final firstStart = controller.startNewSession(SessionType.wordSession);
      await blockingRepository.entered.future;

      await expectLater(
        controller.startNewSession(SessionType.wordSession),
        throwsStateError,
      );

      blockingRepository.release.complete();
      expect(await firstStart, StartSessionResult.noExerciseAvailable);
    });
  });
}

final class _BlockingSessionRepository extends SessionRepository {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();

  _BlockingSessionRepository(super.database, {required super.exerciseRepository});

  @override
  Future<List<SessionResult>> getAllActiveSessionResult() async {
    entered.complete();
    await release.future;
    return [];
  }
}
