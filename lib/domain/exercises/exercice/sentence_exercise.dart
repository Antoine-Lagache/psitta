import 'package:psitta/domain/exercises/exercice/exercise.dart';
import 'package:psitta/domain/exercises/sentence/sentence_group.dart';
import 'package:psitta/domain/exercises/sentence/sentence_instance.dart';
import 'package:psitta/domain/content/content.dart';

export 'package:psitta/domain/exercises/sentence/sentence_group.dart';

/// class representing a sentence exercise. (contains several sentences)
class SentenceExercise extends Exercise {
  final SentenceGroup _sentences;

  // The number of times the user will train after the exercise is completed.
  // (the user will be asked to answer this number of sentences)
  int trainingCount;

  SentenceExercise(
    this._sentences,
    this.trainingCount, {
    required super.status,
    required super.srsState,
    required super.history,
  }) {
    assert(trainingCount <= _sentences.sentences.length);
  }

  @override
  ExercisePrompt getPrompt() {
    Content content = _getSentence().content;
    return ExercisePrompt.fromFields(content.fields);
  }

  /// Returns the sentence with the lowest score (the one that is less known)
  /// No randomness is used here
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
    if (status == ExerciseStatus.consolidating) {
      _getSentence().state.updateState(answer.grade);
      trainingCount--;
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
