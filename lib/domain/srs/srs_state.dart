import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/fsrs_scheduler_config.dart';

/// Domain adapter around the vendored FSRS-6 card model.
///
/// Only answers that affect scheduling belong here; callers exclude training.
/// Uses the supplied scheduler configuration; its defaults disable fuzzing so
/// previews are reproducible. Session limits and day boundaries are not FSRS
/// inputs.
class SRSState {
  fsrs.Card _card;

  SRSState({
    int exerciseId = 0,
    fsrs.State state = fsrs.State.learning,
    int? step,
    double? stability,
    double? difficulty,
    DateTime? due,
    DateTime? lastReview,
  }) : _card = fsrs.Card(
         cardId: exerciseId,
         state: state,
         step: step,
         stability: stability,
         difficulty: difficulty,
         // FSRS requires a concrete date even for unseen cards. This is only
         // a deterministic placeholder; lastReview controls eligibility.
         due: due ?? DateTime.utc(1970),
         lastReview: lastReview,
       );

  SRSState.clone(SRSState other) : _card = other._card.copyWith();

  int get exerciseId => _card.cardId;
  fsrs.State get state => _card.state;
  int? get step => _card.step;
  double? get stability => _card.stability;
  double? get difficulty => _card.difficulty;
  DateTime get due => _card.due;
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

  void applyAnswer(SubmittedExerciseAnswer answer, FsrsSchedulerConfig config) {
    _card = _review(answer, config);
  }

  Duration previewInterval(PreviewExerciseAnswer answer, FsrsSchedulerConfig config) {
    final result = _review(answer, config);
    return result.due.difference(result.lastReview!);
  }

  fsrs.Card _review(ExerciseAnswer answer, FsrsSchedulerConfig config) {
    final at = answer.at.toUtc();
    if (lastReview != null && at.isBefore(lastReview!)) {
      throw ArgumentError.value(answer.at, 'at', 'Answer precedes last review');
    }
    return config
        .createScheduler()
        .reviewCard(_card, _rating(answer.grade), reviewDateTime: at)
        .card;
  }

  static fsrs.Rating _rating(Grade grade) => fsrs.Rating.fromValue(grade.toInt());
}
