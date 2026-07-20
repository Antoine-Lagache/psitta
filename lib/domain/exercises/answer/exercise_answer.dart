import 'package:psitta/domain/srs/grade.dart';

export 'package:psitta/domain/srs/grade.dart';

part 'submitted_exercise_answer.dart';
part 'preview_exercise_answer.dart';

/// represent the answer of the user to an Exercise.
sealed class ExerciseAnswer {
  Grade get grade;
  DateTime get at;
}
