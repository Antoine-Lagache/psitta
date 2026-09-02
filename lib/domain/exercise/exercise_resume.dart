import 'package:psitta/domain/exercise/exercise_status.dart';

/// Minimal transient exercise state stored while a session is unfinished.
class ExerciseResume {
  final int exerciseId;
  final ExerciseStatus status;
  final int? trainingCount;

  ExerciseResume({required this.exerciseId, required this.status, this.trainingCount});
}
