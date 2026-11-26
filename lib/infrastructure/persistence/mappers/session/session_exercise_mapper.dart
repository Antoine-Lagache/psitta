import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';

import 'package:psitta/infrastructure/persistence/models/session_result/session_exercise_persistence.dart';

/// Translates the transient exercise state of an active session.
class SessionExerciseMapper {
  const SessionExerciseMapper();

  static ExerciseResume toDomain(SessionExercisePersistence persistence) {
    return ExerciseResume(
      exerciseId: ExerciseProgressId(persistence.exerciseId),
      status: ExerciseStatus.fromCode(persistence.statusCode),
      trainingCount: persistence.trainingCount,
    );
  }

  static SessionExercisePersistence toPersistence(ExerciseResume domain) {
    return SessionExercisePersistence(
      exerciseId: domain.exerciseId.value,
      statusCode: domain.status.code,
      trainingCount: domain.trainingCount,
    );
  }
}
