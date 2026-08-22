import 'package:psitta/domain/exercise/exercise.dart';

export 'package:psitta/domain/exercise/exercise.dart';

/// Class responsible for scheduling exercises based on their SRS state.
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

  // Selects a new exercise to present in the session.
  // The selected exercise can be accessed through nextExercise.
  void selectNextExercise(DateTime now) {
    Exercise? learning; // was at least already saw once in the session
    Exercise? candidate; // exercise not seen in this session or in training/consolidating
    final shuffled = List.of(exercises)..shuffle();
    for (Exercise a in shuffled) {
      switch (a.status) {
        case ExerciseStatus.learning || ExerciseStatus.relearning:
          assert(a.srsState.nextReview != null);
          // for learning exercise, the time of the next review give the priority
          learning ??= a;
          if (learning.srsState.nextReview!.isAfter(a.srsState.nextReview!)) {
            learning = a;
          }
        case ExerciseStatus.consolidating ||
            ExerciseStatus.newExercise ||
            ExerciseStatus.toReview:
          candidate ??= a; // new exercise picked at random
        case ExerciseStatus.completed:
          continue;
      }
    }

    // if one is null, we return the other
    if (learning == null) {
      _currentExercise = candidate;
      return;
    }
    if (candidate == null) {
      _currentExercise = learning;
      return;
    }

    if (learning.srsState.nextReview!.isBefore((now))) {
      // if the next exercise inlearning should be review now we pick it
      _currentExercise = learning;
    } else {
      // else : we pick a new Exercise
      _currentExercise = candidate;
    }
  }
}
