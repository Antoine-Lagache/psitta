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
      completedOnly: true,
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
    int numberOfAnswers = 0;
    int numberOfExercisesCompleted = 0;

    final numberOfSessionsBySessionType = List<int>.filled(SessionType.values.length, 0);

    final numberOfAnswersByStatus = List<int>.filled(ExerciseStatus.values.length, 0);

    Duration totalTimeSpent = Duration.zero;
    for (final session in sessions) {
      numberOfSessionsBySessionType[session.sessionType.index]++;

      for (final status in ExerciseStatus.values) {
        final count = session.getNumberOfAnswersByStatus(status);

        numberOfAnswersByStatus[status.index] += count;
        numberOfAnswers += count;
      }

      numberOfExercisesCompleted += session.numberOfUniqueExercisesCompleted;

      totalTimeSpent += session.totalTimeSpent;
    }

    return SessionStatistics(
      numberOfSessions: sessions.length,
      numberOfSessionsBySessionType: numberOfSessionsBySessionType,
      numberOfAnswers: numberOfAnswers,
      numberOfExercisesCompleted: numberOfExercisesCompleted,
      numberOfAnswersByStatus: numberOfAnswersByStatus,
      totalTimeSpent: totalTimeSpent,
      numberOfTimedSessions: sessions.length,
      averageTimePerSession: sessions.isEmpty
          ? Duration.zero
          : totalTimeSpent ~/ sessions.length,
      averageNumberOfAnswersPerSession: sessions.isEmpty
          ? 0.0
          : numberOfAnswers / sessions.length,
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
