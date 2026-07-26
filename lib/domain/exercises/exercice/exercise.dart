import 'package:psitta/domain/exercises/answer/exercise_answer.dart';
import 'package:psitta/domain/exercises/exercise_status.dart';
import 'package:psitta/domain/prompt/exercise_prompt.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';

export 'package:psitta/domain/exercises/answer/exercise_answer.dart';
export 'package:psitta/domain/exercises/exercise_status.dart';
export 'package:psitta/domain/prompt/exercise_prompt.dart';
export 'package:psitta/domain/srs/srs_config.dart';
export 'package:psitta/domain/srs/srs_state.dart';

/// Abstract class representing an exercise.
/// Manages the intra-session algorithm and SRS state of the exercise.
abstract class Exercise {
  ExerciseStatus status;

  SRSState srsState;
  List<SubmittedExerciseAnswer> history;

  Exercise({required this.status, required this.srsState, required this.history});

  /// Returns the exercise prompt (for the UI)
  ExercisePrompt getPrompt();

  /// Submits the user's answer with a Grade and updates the SRS state
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    assert(status != ExerciseStatus.completed);
    srsState.applyAnswer(answer, config);
    history.add(answer);

    final DateTime nextDay = DateTime(
      answer.at.year,
      answer.at.month,
      answer.at.day,
    ).add(config.dayBoundary).toUtc();

    if (answer.at.toUtc().add(srsState.interval).isAfter(nextDay) && !srsState.isInLearning) {
      status = ExerciseStatus.completed;
    } else {
      if (status == ExerciseStatus.newExercise) {
        status = ExerciseStatus.learning;
      } else if (status == ExerciseStatus.toreview) {
        status = ExerciseStatus.relearning;
      }
    }
  }

  /// Returns the preview interval for a given grade
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    return srsState.previewInterval(answer, config);
  }

  /// Checks if a Grade is allowed for this exercise
  bool isGradeAllowed(Grade grade) {
    // By default, all grades are allowed
    return true;
  }
}
