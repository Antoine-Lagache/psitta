import 'package:psitta/domain/srs/grade.dart';

export 'package:psitta/domain/srs/grade.dart';

part 'submitted_exercise_answer.dart';
part 'preview_exercise_answer.dart';

/// Carries the grade and timestamp shared by previewed and submitted answers.
sealed class ExerciseAnswer {
  Grade get grade;
  DateTime get at;
}
