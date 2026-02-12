import '../../srs/grade.dart';

part 'real_exercise_answer.dart';
part 'preview_exercise_answer.dart';

/// represent the answer of the user to an Exercise.
sealed class ExerciseAnswer {
  Grade get grade;
  DateTime get at;
}
