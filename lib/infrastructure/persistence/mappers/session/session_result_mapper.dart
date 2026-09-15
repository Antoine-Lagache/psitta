import 'package:psitta/domain/sessions/session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/infrastructure/persistence/models/session_result/session_result_persistence.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';

/// Translates session aggregates and stable enum codes for persistence.
class SessionResultMapper {
  const SessionResultMapper();

  static SessionResultPersistence toPersistence(SessionResult domain) {
    return SessionResultPersistence(
      id: domain.id,
      sessionTypeIndex: domain.sessionType.code,
      uniqueExercisesCompleted: domain.numberOfUniqueExercisesCompleted,
      // ExerciseStatus codes currently match their positions in this list.
      // This mapping must become explicit if those values ever diverge.
      statusCounts: domain.numberOfAnswersByStatus.asMap().entries.map((entry) {
        return StatusCountPersistence(statusCode: entry.key, answerCount: entry.value);
      }).toList(),
      totalTimeSpent: safeFromDuration(domain.totalTimeSpent),
      startedAt: toIsoUtc(domain.startedAt),
      endAt: toIsoUtc(domain.endAt),
    );
  }

  static SessionResult toDomain(SessionResultPersistence persistence) {
    final numberOfAnswersByStatus = List<int>.filled(ExerciseStatus.values.length, 0);
    for (final statusCount in persistence.statusCounts) {
      // Persisted status codes currently double as list indices.
      numberOfAnswersByStatus[statusCount.statusCode] = statusCount.answerCount;
    }

    return SessionResult(
        id: persistence.id,
        sessionType: SessionType.fromCode(persistence.sessionTypeIndex),
        totalTimeSpent: safeToDuration(persistence.totalTimeSpent),
      )
      ..numberOfUniqueExercisesCompleted = persistence.uniqueExercisesCompleted
      ..numberOfAnswersByStatus = numberOfAnswersByStatus
      ..startedAt = safeParseDate(persistence.startedAt)
      ..endAt = safeParseDate(persistence.endAt);
  }
}
