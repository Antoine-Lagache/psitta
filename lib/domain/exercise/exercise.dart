import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';

export 'package:psitta/domain/answer/exercise_answer.dart';
export 'package:psitta/domain/exercise/exercise_resume.dart';
export 'package:psitta/domain/history/exercise_history_entry.dart';
export 'package:psitta/domain/exercise/exercise_status.dart';
export 'package:psitta/domain/srs/srs_config.dart';
export 'package:psitta/domain/srs/srs_state.dart';

/// Base runtime model that coordinates intra-session status and SRS state.
abstract class Exercise {
  final int id;
  ExerciseStatus status;

  SRSState srsState;

  /// Answer events created since this exercise was loaded or last persisted.
  List<ExerciseHistoryEntry> newHistoryEntry;

  Exercise({required this.id, required this.status, required this.srsState})
    : newHistoryEntry = [];

  /// Returns the identifier used by the application layer to load the content.
  int getContentId();

  /// Captures the transient state required to pause and resume a session.
  ExerciseResume getResume();

  /// Applies an answer to the SRS state and advances the session status.
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    if (status == ExerciseStatus.completed) {
      throw StateError('Cannot answer a completed exercise');
    }
    if (!isGradeAllowed(answer.grade)) {
      throw StateError("The grade is not allowed by this exercise");
    }

    srsState.applyAnswer(answer, config);

    DateTime nextDay = DateTime(
      answer.at.year,
      answer.at.month,
      answer.at.day,
    ).add(config.dayBoundary);
    if (!nextDay.isAfter(answer.at)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }

    if (answer.at.add(srsState.interval).isAfter(nextDay) &&
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

  /// Returns the interval produced by [answer] without mutating this exercise.
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    return srsState.previewInterval(answer, config);
  }

  /// Returns whether this exercise type accepts [grade].
  bool isGradeAllowed(Grade grade) {
    // By default, all grades are allowed
    return true;
  }
}
