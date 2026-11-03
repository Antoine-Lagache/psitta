import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/exercise/exercise_resume.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
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

  /// Number of successful in-session practice answers still required.
  int trainingCount;

  /// Number of practice answers configured for a new session.
  final int trainingCountMax;

  Exercise({
    required this.id,
    required this.status,
    required this.srsState,
    this.trainingCountMax = 0,
    int? trainingCount,
  }) : trainingCount = trainingCount ?? trainingCountMax,
       newHistoryEntry = [] {
    if (trainingCountMax < 0 ||
        this.trainingCount < 0 ||
        this.trainingCount > trainingCountMax) {
      throw ArgumentError('Training count must be between 0 and its configured maximum');
    }
  }

  /// Returns the identifier used by the application layer to load the content.
  int getContentId();

  /// Captures the transient state required to pause and resume a session.
  ExerciseResume getResume() =>
      ExerciseResume(exerciseId: id, status: status, trainingCount: trainingCount);

  /// Applies an answer to the SRS state and advances the session status.
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    if (status == ExerciseStatus.completed) {
      throw StateError('Cannot answer a completed exercise');
    }
    if (!isGradeAllowed(answer.grade)) {
      throw StateError("The grade is not allowed by this exercise");
    }

    final answeredStatus = status;
    recordAnswer(answer, answeredStatus);
    onAnswer(answer);

    if (answeredStatus == ExerciseStatus.consolidating) {
      if (!answer.grade.isFail) trainingCount--;
      if (trainingCount == 0) status = ExerciseStatus.completed;
      return;
    }

    srsState.applyAnswer(answer, config.fsrsScheduler);

    DateTime nextDay = DateTime(
      answer.at.year,
      answer.at.month,
      answer.at.day,
    ).add(config.dayBoundary);
    if (!nextDay.isAfter(answer.at)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }

    if (answer.at.add(srsState.interval).isAfter(nextDay) && !srsState.isInLearning) {
      status = ExerciseStatus.completed;
    } else {
      if (status == ExerciseStatus.newExercise) {
        status = ExerciseStatus.learning;
      } else if (status == ExerciseStatus.toReview) {
        status = ExerciseStatus.relearning;
      }
    }

    if (status == ExerciseStatus.completed && trainingCount > 0) {
      status = ExerciseStatus.consolidating;
    }
  }

  /// Records an answer; subtypes may attach subtype-specific history details.
  void recordAnswer(SubmittedExerciseAnswer answer, ExerciseStatus answeredStatus) {
    newHistoryEntry.add(
      ExerciseHistoryEntry.fromAnswer(
        answer: answer,
        exerciseId: id,
        status: answeredStatus,
      ),
    );
  }

  /// Updates subtype-specific practice state for a submitted answer.
  void onAnswer(SubmittedExerciseAnswer answer) {}

  /// Returns the interval produced by [answer] without mutating this exercise.
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    if (!hasMeaningfulPreviewInterval) {
      throw StateError('This exercise phase does not update the SRS interval');
    }
    if (!isGradeAllowed(answer.grade)) {
      throw StateError('The grade is not allowed by this exercise');
    }
    return srsState.previewInterval(answer, config.fsrsScheduler);
  }

  /// Whether answering the exercise currently updates its SRS interval.
  bool get hasMeaningfulPreviewInterval => status != ExerciseStatus.consolidating;

  /// Returns whether this exercise type accepts [grade].
  bool isGradeAllowed(Grade grade) {
    // By default, all grades are allowed
    return true;
  }
}
