import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/fsrs_scheduler_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime.utc(2026, 11, 2, 10);
  final config = FsrsSchedulerConfig();

  void answer(SRSState state, Grade grade, DateTime at) {
    state.applyAnswer(SubmittedExerciseAnswer(grade: grade, answeredAt: at), config);
  }

  test('new state has no scheduled review or model estimates', () {
    final state = SRSState(exerciseId: 7);
    expect(state.nextReview, isNull);
    expect(state.lastReview, isNull);
    expect(state.interval, Duration.zero);
    expect(state.stability, isNull);
    expect(state.difficulty, isNull);
    expect(state.isInLearning, isTrue);
  });

  test('all FSRS grades match upstream semantics without mutating previews', () {
    final ratings = {
      Grade.again: fsrs.Rating.again,
      Grade.hard: fsrs.Rating.hard,
      Grade.good: fsrs.Rating.good,
      Grade.easy: fsrs.Rating.easy,
    };
    final scheduler = fsrs.Scheduler(enableFuzzing: false);
    final initialIntervals = {
      Grade.again: const Duration(minutes: 1),
      Grade.hard: const Duration(minutes: 5, seconds: 30),
      Grade.good: const Duration(minutes: 10),
      Grade.easy: const Duration(days: 16),
    };
    for (final entry in ratings.entries) {
      final state = SRSState(exerciseId: 7);
      final expected = scheduler
          .reviewCard(fsrs.Card(cardId: 7), entry.value, reviewDateTime: start)
          .card;
      final preview = state.previewInterval(
        PreviewExerciseAnswer(grade: entry.key, at: start),
        config,
      );
      expect(state.lastReview, isNull);
      expect(state.stability, isNull);
      expect(state.learningStepIndex, 0);
      answer(state, entry.key, start);
      expect(state.interval, preview);
      expect(state.interval, initialIntervals[entry.key]);
      expect(state.nextReview, expected.due);
      expect(state.stability, expected.stability);
      expect(state.difficulty, expected.difficulty);
    }
  });

  test('learning graduates, a failed review relearns, and Good graduates again', () {
    final state = SRSState(exerciseId: 7);
    answer(state, Grade.good, start);
    expect(state.interval, const Duration(minutes: 10));
    expect(state.learningStepIndex, 1);
    answer(state, Grade.good, state.nextReview!);
    expect(state.isInLearning, isFalse);
    expect(state.learningStepIndex, -1);
    final due = state.nextReview!;
    final before = SRSState.clone(state);
    final preview = state.previewInterval(
      PreviewExerciseAnswer(grade: Grade.again, at: due),
      config,
    );
    expect(state.nextReview, before.nextReview);
    expect(state.stability, before.stability);
    expect(state.difficulty, before.difficulty);
    expect(state.isInLearning, isFalse);
    answer(state, Grade.again, due);
    expect(state.interval, preview);
    expect(state.interval, const Duration(minutes: 10));
    expect(state.isInLearning, isTrue);
    expect(state.isRelearning, isTrue);
    answer(state, Grade.good, state.nextReview!);
    expect(state.isInLearning, isFalse);
    expect(state.isRelearning, isFalse);
  });

  test('clones and copies do not share mutable card state', () {
    final original = SRSState(exerciseId: 7);
    final clone = SRSState.clone(original);
    answer(clone, Grade.easy, start);
    expect(original.lastReview, isNull);
    original.copyFrom(clone);
    final due = original.nextReview;
    answer(clone, Grade.again, clone.nextReview!);
    expect(original.nextReview, due);
    expect(original.isInLearning, isFalse);
    expect(() => original.copyFrom(SRSState(exerciseId: 8)), throwsArgumentError);
  });

  test('normalizes local instants and rejects reverse chronological answers', () {
    final state = SRSState(exerciseId: 7);
    answer(state, Grade.good, start.toLocal());
    expect(state.lastReview, start);
    expect(state.lastReview!.isUtc, isTrue);
    final due = state.nextReview;
    final earlier = start.subtract(const Duration(seconds: 1));
    expect(() => answer(state, Grade.good, earlier), throwsArgumentError);
    expect(
      () => state.previewInterval(
        PreviewExerciseAnswer(grade: Grade.good, at: earlier),
        config,
      ),
      throwsArgumentError,
    );
    expect(state.nextReview, due);
    answer(state, Grade.good, start);
    expect(state.lastReview, start);
  });

  test('review previews stay deterministic over a late-review history', () {
    final first = SRSState(exerciseId: 7);
    final replay = SRSState(exerciseId: 7);
    var at = start;
    for (final grade in [Grade.easy, Grade.good, Grade.hard, Grade.again, Grade.good]) {
      final preview = first.previewInterval(
        PreviewExerciseAnswer(grade: grade, at: at),
        config,
      );
      expect(
        first.previewInterval(PreviewExerciseAnswer(grade: grade, at: at), config),
        preview,
      );
      answer(first, grade, at);
      answer(replay, grade, at);
      expect(first.interval, preview);
      expect(first.nextReview, replay.nextReview);
      expect(first.stability, replay.stability);
      expect(first.difficulty, replay.difficulty);
      at = first.nextReview!.add(const Duration(days: 3));
    }
  });
}
