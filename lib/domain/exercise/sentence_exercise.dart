import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/sentences/sentence_group.dart';

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
    if (_sentences.sentences.isEmpty) {
      throw ArgumentError('A SentenceExercise requires at least one sentence');
    }
    if (this.trainingCount < 0 || this.trainingCount > _sentences.sentences.length) {
      throw ArgumentError('Training count must match the sentence group size');
    }
  }

  @override
  int getContentId() => _sentences.getSentence().contentId;

  @override
  ExerciseResume getResume() {
    return ExerciseResume(exerciseId: id, status: status, trainingCount: trainingCount);
  }

  @override
  bool isGradeAllowed(Grade grade) {
    if (grade == Grade.easy) {
      return false;
    }
    return true; // Again, Hard, and Good are allowed.
  }

  @override
  bool get hasMeaningfulPreviewInterval => status != ExerciseStatus.consolidating;

  @override
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    if (status == ExerciseStatus.completed) {
      throw StateError('Cannot answer a completed exercise');
    }
    if (!isGradeAllowed(answer.grade)) {
      throw StateError('The grade is not allowed by this exercise');
    }

    newHistoryEntry.add(
      ExerciseHistoryEntry.fromAnswer(
        answer: answer,
        exerciseId: id,
        status: status,
        sentenceInstanceId: _sentences.getSentence().id,
      ),
    );

    _sentences.updateStates(answer.grade);

    if (status == ExerciseStatus.consolidating) {
      if (!answer.grade.isFail) trainingCount--;

      if (trainingCount == 0) {
        status = ExerciseStatus.completed;
      }
      return;
    } else {
      super.applyAnswer(answer, config);

      if (status == ExerciseStatus.completed && trainingCount > 0) {
        status = ExerciseStatus.consolidating;
      }
    }
  }
}
