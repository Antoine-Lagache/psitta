import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/srs/srs_state.dart';

SRSState reviewSrsState({
  required int exerciseId,
  required DateTime lastReview,
  required Duration interval,
  double stability = 8,
  double difficulty = 5,
}) {
  return SRSState(
    exerciseId: exerciseId,
    state: fsrs.State.review,
    stability: stability,
    difficulty: difficulty,
    due: lastReview.add(interval),
    lastReview: lastReview,
  );
}

SRSState learningSrsState({
  required int exerciseId,
  required DateTime lastReview,
  required Duration interval,
  int step = 0,
  bool relearning = false,
}) {
  return SRSState(
    exerciseId: exerciseId,
    state: relearning ? fsrs.State.relearning : fsrs.State.learning,
    step: step,
    due: lastReview.add(interval),
    lastReview: lastReview,
  );
}
