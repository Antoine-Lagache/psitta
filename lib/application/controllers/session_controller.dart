import 'dart:math';

import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/application/models/session/start_session_result.dart';
import 'package:psitta/application/models/session/submit_answer_result.dart';
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';

/// Coordinates the application use cases for starting and running a session.
class SessionController {
  static final Stopwatch _defaultMonotonicClock = Stopwatch()..start();

  Session? _activeSession;
  bool get hasActiveSession => _activeSession != null;

  Duration? _activeSegmentStartedAt;

  bool _operationInProgress = false;

  final SessionRepository _sessionRepository;
  final ExerciseRepository _exerciseRepository;
  final ContentController _contentController;
  final DateTime Function() _now;
  final Duration Function() _elapsedNow;

  final SRSConfig config;

  SessionController({
    required SessionRepository sessionRepository,
    required ExerciseRepository exerciseRepository,
    required ContentController contentController,
    SRSConfig? config,
    DateTime Function()? now,
    Duration Function()? elapsedNow,
  }) : _sessionRepository = sessionRepository,
       _exerciseRepository = exerciseRepository,
       _contentController = contentController,
       config = config ?? SRSConfig(),
       _now = now ?? DateTime.now,
       _elapsedNow = elapsedNow ?? _readDefaultMonotonicClock;

  /// Creates, starts, and persists a session from due and new exercises.
  Future<StartSessionResult> startNewSession(SessionType sessionType) {
    return _runExclusive(() async {
      if (_activeSession != null) {
        return StartSessionResult.activeSessionAlreadyExists;
      }

      final persistedSessions = await _sessionRepository.getAllActiveSessionResult();
      if (persistedSessions.any((session) => session.sessionType == sessionType)) {
        return StartSessionResult.activeSessionAlreadyExists;
      }

      final exerciseType = _exerciseTypeFor(sessionType);

      final dueExercises = await _exerciseRepository.getDueExercises(
        _now(),
        config.reviewCount,
        exerciseType,
      );
      final newExercises = await _exerciseRepository.getNewExercises(
        config.newCount,
        exerciseType,
      );
      final exercises = dueExercises + newExercises;

      if (exercises.isEmpty) {
        return StartSessionResult.noExerciseAvailable;
      }

      final session = Session(
        exercises: exercises,
        sessionType: sessionType,
        config: config,
      );
      session.beginSession(_now());

      final id = await _sessionRepository.save(session);
      session.intermediateResult.id = id;
      _startTimingSegment();
      _activeSession = session;

      return StartSessionResult.started;
    });
  }

  /// Restores the most recently started persisted session of [sessionType].
  Future<bool> resumeActiveSession(SessionType sessionType) {
    return _runExclusive(() async {
      if (_activeSession != null) {
        throw StateError('A session is already active');
      }

      final persistedSessions = await _sessionRepository.getAllActiveSessionResult();
      final activeSession = _mostRecentSessionOfType(
        persistedSessions,
        sessionType,
      );

      if (activeSession == null) {
        return false;
      }

      final session = await _sessionRepository.getActiveSession(
        activeSession,
        config,
      );
      session.resumeSession(_now());
      _startTimingSegment();
      _activeSession = session;
      return true;
    });
  }

  /// Builds the home-screen counts for every supported session type.
  Future<List<SessionOverview>> getSessionOverviews() async {
    final now = _now();
    final activeSessions = await _sessionRepository.getAllActiveSessionResult();
    final overviews = <SessionOverview>[];

    for (final sessionType in SessionType.values) {
      final activeSession = _mostRecentSessionOfType(
        activeSessions,
        sessionType,
      );

      final overview = activeSession == null
          ? await _buildNewSessionOverview(sessionType, now)
          : await _buildActiveSessionOverview(sessionType, activeSession);
      overviews.add(overview);
    }

    return List.unmodifiable(overviews);
  }

  Future<SessionOverview> _buildActiveSessionOverview(
    SessionType sessionType,
    SessionResult activeSession,
  ) async {
    final sessionResultId = activeSession.id;
    if (sessionResultId == null) {
      throw StateError('An active persisted session must have an id');
    }

    final counts = await _sessionRepository.countActiveSessionExercisesByStatus(
      sessionResultId,
    );
    var reviewExerciseCount = 0;

    for (final entry in counts.entries) {
      switch (entry.key) {
        case ExerciseStatus.newExercise || ExerciseStatus.completed:
          break;
        case ExerciseStatus.toReview ||
            ExerciseStatus.learning ||
            ExerciseStatus.relearning ||
            ExerciseStatus.consolidating:
          reviewExerciseCount += entry.value;
      }
    }

    return SessionOverview(
      sessionType: sessionType,
      newExerciseCount: counts[ExerciseStatus.newExercise] ?? 0,
      reviewExerciseCount: reviewExerciseCount,
      hasActiveSession: true,
    );
  }

  Future<SessionOverview> _buildNewSessionOverview(
    SessionType sessionType,
    DateTime now,
  ) async {
    final exerciseType = _exerciseTypeFor(sessionType);
    final reviewExerciseCount = await _exerciseRepository.countDueExercises(
      now,
      exerciseType,
    );
    final newExerciseCount = await _exerciseRepository.countNewExercises(
      exerciseType,
    );

    return SessionOverview(
      sessionType: sessionType,
      newExerciseCount: min(newExerciseCount, config.newCount),
      reviewExerciseCount: min(reviewExerciseCount, config.reviewCount),
      hasActiveSession: false,
    );
  }

  String _exerciseTypeFor(SessionType sessionType) {
    return switch (sessionType) {
      SessionType.wordSession => 'word',
      SessionType.sentenceSession => 'sentence',
    };
  }

  /// Loads the content selected by the active session.
  Future<Content> getCurrentExerciseContent() async {
    final contentId = _requireActiveSession().getCurrentContentId();

    final content = await _contentController.getContentById(contentId);
    if (content == null) {
      throw StateError('Missing content with id $contentId');
    }
    return content;
  }

  List<Grade> getCurrentExerciseAllowedGrade() {
    return _requireActiveSession().getCurrentExerciseAllowedGrade();
  }

  /// Previews every allowed grade using the same reference timestamp.
  Map<Grade, Duration> getCurrentExercisePreviewIntervals() {
    final session = _requireActiveSession();
    final now = _now();
    final intervals = <Grade, Duration>{};

    for (final grade in session.getCurrentExerciseAllowedGrade()) {
      intervals[grade] = session.getPreviewInterval(
        PreviewExerciseAnswer(grade: grade, at: now),
      );
    }

    return Map.unmodifiable(intervals);
  }

  /// Applies [grade] and persists the resulting session-level progress.
  Future<SubmitAnswerResult> submitAnswer(Grade grade) {
    return _runExclusive(() async {
      final session = _requireActiveSession();
      if (!session.getCurrentExerciseAllowedGrade().contains(grade)) {
        throw StateError('This grade is not allowed by the exercise');
      }

      final answeredExercise = session.currentExercise;
      final now = _now();

      try {
        final segmentDuration = _stopTimingSegment();
        session.submitAnswer(SubmittedExerciseAnswer(grade: grade, answeredAt: now));
        session.addTimeSpent(segmentDuration);

        final sessionFinished = session.isSessionFinished();
        if (sessionFinished) {
          session.endSession(now);
        }

        await _sessionRepository.saveAnswerProgress(session, answeredExercise);

        if (sessionFinished) {
          _activeSession = null;
          return SubmitAnswerResult.sessionCompleted;
        }

        _startTimingSegment();
        return SubmitAnswerResult.nextExercise;
      } on Object {
        _activeSegmentStartedAt = null;
        _activeSession = null;
        rethrow;
      }
    });
  }

  Future<void> endSession() {
    return _runExclusive(() async {
      final session = _requireActiveSession();

      try {
        session.addTimeSpent(_stopTimingSegment());
        session.endSession(_now());
        await _sessionRepository.completeSession(session);
        _activeSession = null;
      } on Object {
        _activeSegmentStartedAt = null;
        _activeSession = null;
        rethrow;
      }
    });
  }

  Future<void> pauseSession() {
    return _runExclusive(() async {
      final session = _requireActiveSession();

      try {
        session.addTimeSpent(_stopTimingSegment());
        await _sessionRepository.update(session);
        _activeSession = null;
      } on Object {
        _activeSegmentStartedAt = null;
        _activeSession = null;
        rethrow;
      }
    });
  }

  Session _requireActiveSession() {
    return _activeSession ?? (throw StateError('A session must be active first'));
  }

  Future<T> _runExclusive<T>(Future<T> Function() operation) async {
    if (_operationInProgress) {
      throw StateError('Another session operation is already in progress');
    }

    _operationInProgress = true;
    try {
      return await operation();
    } finally {
      _operationInProgress = false;
    }
  }

  void _startTimingSegment() {
    if (_activeSegmentStartedAt != null) {
      throw StateError('A session timing segment is already active');
    }
    _activeSegmentStartedAt = _elapsedNow();
  }

  Duration _stopTimingSegment() {
    final startedAt = _activeSegmentStartedAt;
    if (startedAt == null) {
      throw StateError('No session timing segment is active');
    }

    final endedAt = _elapsedNow();
    if (endedAt.compareTo(startedAt) < 0) {
      throw StateError('The monotonic clock moved backwards');
    }

    _activeSegmentStartedAt = null;
    return endedAt - startedAt;
  }

  static Duration _readDefaultMonotonicClock() {
    return _defaultMonotonicClock.elapsed;
  }

  static SessionResult? _mostRecentSessionOfType(
    List<SessionResult> sessions,
    SessionType sessionType,
  ) {
    final matchingSessions =
        sessions.where((session) => session.sessionType == sessionType).toList()
          ..sort(_compareMostRecentFirst);

    return matchingSessions.isEmpty ? null : matchingSessions.first;
  }

  static int _compareMostRecentFirst(SessionResult left, SessionResult right) {
    final leftStartedAt = left.startedAt;
    final rightStartedAt = right.startedAt;

    if (leftStartedAt != null && rightStartedAt != null) {
      final dateComparison = rightStartedAt.compareTo(leftStartedAt);
      if (dateComparison != 0) {
        return dateComparison;
      }
    } else if (leftStartedAt == null && rightStartedAt != null) {
      return 1;
    } else if (leftStartedAt != null && rightStartedAt == null) {
      return -1;
    }

    return (right.id ?? -1).compareTo(left.id ?? -1);
  }
}
