import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/answer/exercise_answer.dart';

/// FSRS-6 state, staged separately until persistence is migrated.
///
/// Only answers that affect scheduling belong here; callers exclude training.
/// Uses upstream defaults, except fuzzing is disabled for reproducible previews
/// and history replay. Session quantities and day boundaries are not SRS inputs.
class SRSState {
  static final fsrs.Scheduler _scheduler = fsrs.Scheduler(enableFuzzing: false);

  fsrs.Card _card;

  SRSState({required int exerciseId})
    : _card = fsrs.Card(cardId: exerciseId, due: DateTime.utc(1970));

  SRSState.clone(SRSState other) : _card = other._card.copyWith();

  int get exerciseId => _card.cardId;
  double? get stability => _card.stability;
  double? get difficulty => _card.difficulty;
  DateTime? get lastReview => _card.lastReview;

  /// Unseen exercises have no scheduled review, regardless of upstream due.
  DateTime? get nextReview => lastReview == null ? null : _card.due;

  /// No interval exists before the first answer.
  Duration get interval =>
      lastReview == null ? Duration.zero : _card.due.difference(lastReview!);

  bool get isInLearning => _card.state != fsrs.State.review;
  bool get isRelearning => _card.state == fsrs.State.relearning;
  int get learningStepIndex => _card.step ?? -1;

  void copyFrom(SRSState other) {
    if (exerciseId != other.exerciseId) {
      throw ArgumentError('Cannot copy SRS state from another exercise');
    }
    _card = other._card.copyWith();
  }

  void applyAnswer(SubmittedExerciseAnswer answer) {
    _card = _review(answer);
  }

  Duration previewInterval(PreviewExerciseAnswer answer) {
    final result = _review(answer);
    return result.due.difference(result.lastReview!);
  }

  fsrs.Card _review(ExerciseAnswer answer) {
    final at = answer.at.toUtc();
    if (lastReview != null && at.isBefore(lastReview!)) {
      throw ArgumentError.value(answer.at, 'at', 'Answer precedes last review');
    }
    return _scheduler.reviewCard(_card, _rating(answer.grade), reviewDateTime: at).card;
  }

  /// Temporary bridge from the five legacy grades; never cast numeric values.
  /// Remove this bridge when stored grades and the exercise/UI contract migrate.
  static fsrs.Rating _rating(Grade grade) => switch (grade) {
    Grade.again || Grade.hard => fsrs.Rating.again,
    Grade.medium => fsrs.Rating.hard,
    Grade.good => fsrs.Rating.good,
    Grade.easy => fsrs.Rating.easy,
  };
}
