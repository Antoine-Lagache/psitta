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
      statusCounts: domain.numberOfExercicesByStatus.asMap().entries.map((entry) {
        return StatusCountPersistence(
          statusCode: entry.key,
          exercisesCompleted: entry.value,
        );
      }).toList(),
      startedAt: toIsoUtc(domain.startedAt),
      endAt: toIsoUtc(domain.endAt),
    );
  }

  static SessionResult toDomain(SessionResultPersistence persistence) {
    final numberOfExercicesByStatus = List<int>.filled(ExerciseStatus.values.length, 0);
    for (final statusCount in persistence.statusCounts) {
      numberOfExercicesByStatus[statusCount.statusCode] = statusCount.exercisesCompleted;
    }

    return SessionResult(
        id: persistence.id,
        sessionType: SessionType.fromCode(persistence.sessionTypeIndex),
      )
      ..numberOfUniqueExercisesCompleted = persistence.uniqueExercisesCompleted
      ..numberOfExercicesByStatus = numberOfExercicesByStatus
      ..startedAt = safeParseDate(persistence.startedAt)
      ..endAt = safeParseDate(persistence.endAt);
  }
}
