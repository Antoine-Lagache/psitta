import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/sentences/sentence_group.dart';
import 'package:psitta/domain/sentences/sentence_instance.dart';

export 'package:psitta/domain/sentences/sentence_group.dart';

/// Selects and trains sentences from one group before completing the exercise.
class SentenceExercise extends Exercise {
  final SentenceGroup _sentences;
  int get groupId => _sentences.id;
  SentenceGroup get sentences => _sentences;

  /// Remaining consolidation answers after the SRS phase completes.
  int trainingCount;

  /// Initial consolidation-answer target for each session.
  final int trainingCountMax;

  SentenceExercise({
    required SentenceGroup sentences,
    required this.trainingCountMax,
    int? trainingCount,
    required super.id,
    required super.status,
    required super.srsState,
  }) : _sentences = sentences,
       trainingCount = trainingCount ?? trainingCountMax {
    // TODO(review): Enforce a non-empty group and valid training count outside
    // debug-only assertions; content selection indexes the first sentence.
    assert(this.trainingCount <= _sentences.sentences.length);
  }

  @override
  int getContentId() => _getSentence().contentId;

  @override
  ExerciseResume getResume() {
    return ExerciseResume(exerciseId: id, status: status, trainingCount: trainingCount);
  }

  /// Deterministically selects the least-known sentence in the group.
  SentenceInstance _getSentence() {
    double minScore = _sentences.sentences[0].state.getscore();
    SentenceInstance sentence = _sentences.sentences[0];

    for (final sentenceInstance in _sentences.sentences) {
      if (sentenceInstance.state.getscore() < minScore) {
        minScore = sentenceInstance.state.getscore();
        sentence = sentenceInstance;
      }
    }
    return sentence;
  }

  @override
  bool isGradeAllowed(Grade grade) {
    if (grade == Grade.easy || grade == Grade.hard) {
      return false;
    }
    return true; // allowed : q = 0, 3, 4
  }

  @override
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    newHistoryEntry.add(
      ExerciseHistoryEntry.fromAnswer(
        answer: answer,
        exerciseId: id,
        status: status,
        sentenceInstanceId: _getSentence().id,
      ),
    );
    if (status == ExerciseStatus.consolidating) {
      _getSentence().state.updateState(answer.grade);
      if (!answer.grade.isFail) trainingCount--;

      if (trainingCount == 0) {
        status = ExerciseStatus.completed;
      }
      return;
    } else {
      _getSentence().state.updateState(answer.grade);
      super.applyAnswer(answer, config);

      if (status == ExerciseStatus.completed && trainingCount > 0) {
        status = ExerciseStatus.consolidating;
      }
    }
  }
}
