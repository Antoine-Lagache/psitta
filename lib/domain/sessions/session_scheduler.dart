import 'package:psitta/domain/exercise/exercise.dart';

export 'package:psitta/domain/exercise/exercise.dart';

/// Selects the next session exercise from transient status and SRS due time.
class SessionScheduler {
  final List<Exercise> exercises;

  Exercise? _currentExercise;
  Exercise? get currentExercise => _currentExercise;

  SessionScheduler(this.exercises);

  bool hasNextExercise() {
    return exercises.any((a) => a.status != ExerciseStatus.completed);
  }

  int countExerciseByStatus(ExerciseStatus status) {
    return exercises.where((a) => a.status == status).length;
  }

  List<ExerciseResume> getResumeList() {
    return exercises.map((e) => e.getResume()).toList();
  }

  /// Selects the next exercise and exposes it through [currentExercise].
  void selectNextExercise(DateTime now) {
    Exercise? learning; // Already seen and waiting for an intra-session review.
    Exercise? candidate; // New, due, or consolidating exercise ready immediately.
    final shuffled = List.of(exercises)..shuffle();
    for (Exercise a in shuffled) {
      switch (a.status) {
        case ExerciseStatus.learning || ExerciseStatus.relearning:
          assert(a.srsState.nextReview != null);
          // Earliest due time takes priority among learning exercises.
          learning ??= a;
          if (learning.srsState.nextReview!.isAfter(a.srsState.nextReview!)) {
            learning = a;
          }
        case ExerciseStatus.consolidating ||
            ExerciseStatus.newExercise ||
            ExerciseStatus.toReview:
          candidate ??= a; // Shuffling makes the first ready candidate random.
        case ExerciseStatus.completed:
          continue;
      }
    }

    // If one category is empty, use the available exercise.
    if (learning == null) {
      _currentExercise = candidate;
      return;
    }
    if (candidate == null) {
      // TODO(review): Decide whether a sole learning exercise should be
      // selected before its next-review time or leave the session waiting.
      _currentExercise = learning;
      return;
    }

    if (learning.srsState.nextReview!.isBefore((now))) {
      // Prefer learning work once its intra-session review is due.
      _currentExercise = learning;
    } else {
      // Otherwise use immediately available work.
      _currentExercise = candidate;
    }
  }
}
