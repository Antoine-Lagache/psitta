import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';

import 'package:psitta/infrastructure/persistence/repositories/exercise_history_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/session_repository.dart';

/// Builds application statistics from persisted sessions and answer history.
class StatisticController {
  final SessionRepository _sessionRepository;
  final ExerciseHistoryRepository _exerciseHistoryRepository;

  StatisticController({
    required SessionRepository sessionRepository,
    required ExerciseHistoryRepository exerciseHistoryRepository,
  }) : _sessionRepository = sessionRepository,
       _exerciseHistoryRepository = exerciseHistoryRepository;

  /// Aggregates session statistics over the half-open requested date range.
  Future<SessionStatistics> getSessionStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await _sessionRepository.getList(
      startedDate: startDate,
      endDate: endDate,
    );

    return _calculateSessionStatistics(sessions);
  }

  /// Aggregates answer statistics over the half-open requested date range.
  Future<ExerciseStatistics> getExerciseStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final history = await _exerciseHistoryRepository.getList(
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateExerciseStatistics(history);
  }

  SessionStatistics _calculateSessionStatistics(List<SessionResult> sessions) {
    int numberOfExercisesAnswered = 0;
    int numberOfExercisesCompleted = 0;

    final numberOfSessionsBySessionType = List<int>.filled(SessionType.values.length, 0);

    final numberOfExercisesByStatus = List<int>.filled(ExerciseStatus.values.length, 0);

    Duration totalTimeSpent = Duration.zero;
    int numberOfTimedSessions = 0;

    for (final session in sessions) {
      numberOfSessionsBySessionType[session.sessionType.index]++;

      for (final status in ExerciseStatus.values) {
        final count = session.getNumberOfExercisesByStatus(status);

        numberOfExercisesByStatus[status.index] += count;
        numberOfExercisesAnswered += count;
      }

      numberOfExercisesCompleted += session.numberOfUniqueExercisesCompleted;

      final timeSpent = session.totalTimeSpent;
      if (timeSpent != null) {
        totalTimeSpent += timeSpent;
        numberOfTimedSessions++;
      }
    }

    return SessionStatistics(
      numberOfSessions: sessions.length,
      numberOfSessionsBySessionType: numberOfSessionsBySessionType,
      numberOfExercisesAnswered: numberOfExercisesAnswered,
      numberOfExercisesCompleted: numberOfExercisesCompleted,
      numberOfExercisesByStatus: numberOfExercisesByStatus,
      totalTimeSpent: totalTimeSpent,
      numberOfTimedSessions: numberOfTimedSessions,
      averageTimePerSession: numberOfTimedSessions == 0
          ? Duration.zero
          : totalTimeSpent ~/ numberOfTimedSessions,
      averageNumberOfExercisesPerSession: sessions.isEmpty
          ? 0.0
          : numberOfExercisesAnswered / sessions.length,
    );
  }

  ExerciseStatistics _calculateExerciseStatistics(List<ExerciseHistoryEntry> history) {
    final numberOfAnswersByGrade = List<int>.filled(Grade.values.length, 0);
    final numberOfAnswersByStatus = List<int>.filled(ExerciseStatus.values.length, 0);

    final exerciseIds = <int>{};

    for (final entry in history) {
      numberOfAnswersByGrade[entry.grade.index]++;
      numberOfAnswersByStatus[entry.status.index]++;
      exerciseIds.add(entry.exerciseId);
    }

    return ExerciseStatistics(
      totalNumberAnswers: history.length,
      numberOfAnswersByGrade: numberOfAnswersByGrade,
      numberOfAnswersByStatus: numberOfAnswersByStatus,
      numberOfDistinctExercisesAnswered: exerciseIds.length,
    );
  }
}
