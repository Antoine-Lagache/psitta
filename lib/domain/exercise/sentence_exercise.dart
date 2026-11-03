import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/sentences/sentence_group.dart';

export 'package:psitta/domain/sentences/sentence_group.dart';

/// Selects and trains sentences from one group before completing the exercise.
class SentenceExercise extends Exercise {
  final SentenceGroup _sentences;
  int get groupId => _sentences.id;
  SentenceGroup get sentences => _sentences;

  SentenceExercise({
    required SentenceGroup sentences,
    required super.trainingCountMax,
    super.trainingCount,
    required super.id,
    required super.status,
    required super.srsState,
  }) : _sentences = sentences {
    if (_sentences.sentences.isEmpty) {
      throw ArgumentError('A SentenceExercise requires at least one sentence');
    }
    if (trainingCountMax > _sentences.sentences.length) {
      throw ArgumentError('Training count must match the sentence group size');
    }
  }

  @override
  int getContentId() => _sentences.getSentence().contentId;

  @override
  bool isGradeAllowed(Grade grade) {
    if (grade == Grade.easy) {
      return false;
    }
    return true; // Again, Hard, and Good are allowed.
  }

  @override
  void recordAnswer(SubmittedExerciseAnswer answer, ExerciseStatus answeredStatus) {
    newHistoryEntry.add(
      ExerciseHistoryEntry.fromAnswer(
        answer: answer,
        exerciseId: id,
        status: answeredStatus,
        sentenceInstanceId: _sentences.getSentence().id,
      ),
    );
  }

  @override
  void onAnswer(SubmittedExerciseAnswer answer) {
    _sentences.updateStates(answer.grade);
  }
}
