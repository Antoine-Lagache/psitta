import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';

import 'package:psitta/infrastructure/persistence/models/session_result/session_exercise_persistence.dart';

class SessionExerciseMapper {
  const SessionExerciseMapper();

  static ExerciseResume toDomain(SessionExercisePersistence persistence) {
    return ExerciseResume(
      exerciseId: persistence.exerciseId,
      status: ExerciseStatus.fromCode(persistence.statusCode),
      trainingCount: persistence.trainingCount,
    );
  }

  static SessionExercisePersistence toPersistence(ExerciseResume domain) {
    return SessionExercisePersistence(
      exerciseId: domain.exerciseId,
      statusCode: domain.status.code,
      trainingCount: domain.trainingCount,
    );
  }
}
