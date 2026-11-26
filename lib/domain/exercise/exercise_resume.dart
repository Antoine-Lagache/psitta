import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';

/// Minimal transient exercise state stored while a session is unfinished.
class ExerciseResume {
  final ExerciseProgressId exerciseId;
  final ExerciseStatus status;
  final int? trainingCount;

  ExerciseResume({required this.exerciseId, required this.status, this.trainingCount});
}
