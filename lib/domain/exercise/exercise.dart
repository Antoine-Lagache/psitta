import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';

export 'package:psitta/domain/answer/exercise_answer.dart';
export 'package:psitta/domain/exercise/exercise_status.dart';
export 'package:psitta/domain/srs/srs_config.dart';
export 'package:psitta/domain/srs/srs_state.dart';
export 'package:psitta/domain/history/exercise_history_entry.dart';

/// Abstract class representing an exercise.
/// Manages the intra-session algorithm and SRS state of the exercise.
abstract class Exercise {
  final int id;
  ExerciseStatus status;

  SRSState srsState;

  // Contain only, new history entries that have not been saved yet.
  List<ExerciseHistoryEntry> newHistoryEntry;

  Exercise({required this.id, required this.status, required this.srsState})
    : newHistoryEntry = [];

  /// Returns the id of the content
  /// The domain doesn't need to know the content itself,
  /// only its id is needed to retrieve it from the database
  int getContentId();

  /// Submits the user's answer with a Grade and updates the SRS state
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    assert(status != ExerciseStatus.completed);
    srsState.applyAnswer(answer, config);

    final DateTime nextDay = DateTime(
      answer.at.year,
      answer.at.month,
      answer.at.day,
    ).add(config.dayBoundary).toUtc();

    if (answer.at.toUtc().add(srsState.interval).isAfter(nextDay) &&
        !srsState.isInLearning) {
      status = ExerciseStatus.completed;
    } else {
      if (status == ExerciseStatus.newExercise) {
        status = ExerciseStatus.learning;
      } else if (status == ExerciseStatus.toReview) {
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
