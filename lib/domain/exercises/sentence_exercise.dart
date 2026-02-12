import 'package:flutter_application_1/domain/exercises/sentence/sentence_group.dart';

import 'answer/exercise_answer.dart';
import '../content/sentence.dart';
import 'exercise.dart';
import '../prompt/exercice_prompt.dart';
import '../srs/grade.dart';
import '../srs/srs_config.dart';

/// Classe représentant un exercice de phrases. (contient plusieurs phrases)
class SentenceExercise extends Exercise {
  // les 2 listes doivent faire la même taille, chaque phrase a son état associé
  final SentenceGroup sentences;

  SentenceExercise(this.sentences, super.status, super.srsState); //TODO: constructor ?

  /// Renvoie un prompt d'une phrase aléatoire pour l'exercice de phrases
  @override
  ExercicePrompt getPrompt() {
    // TODO: use _getSentence, return Prompt of a sentence
    return ExercicePrompt(promptData: {}, keyRecto: [], keyVerso: [], keyMeta: []);
  }

  // ignore: unused_element
  Sentence _getSentence() {
    //TODO: without random, use sentenceStates (then ID if equals)
    return sentences.sentences[0].sentence;
  }

  @override
  bool isGradeAllowed(Grade grade) {
    if (grade == Grade.easy || grade == Grade.hard) {
      return false;
    }
    return true; // alowed : q = 0, 3, 4
  }

  @override
  void applyAnswer(RealExerciseAnswer answer, SRSConfig config) {
    // TODO: update sentence state too
    super.applyAnswer(answer, config);
  }
}
