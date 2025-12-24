import '../content/sentence.dart';
import 'exercice.dart';
import '../prompt/exercice_prompt.dart';
import 'dart:math';
import '../srs/grade.dart';

class SentenceExercice extends Exercice {
  final List<Sentence> sentences = [];
  SentenceExercice(super.status, super.srsState);

  /// Renvoie un prompt d'une phrase aléatoire pour l'exercice de phrases
  @override
  ExercicePrompt getPrompt() {
    // TODO: use getSentence, return Prompt of a sentence
    return ExercicePrompt(promptData: {
      'sentences': sentences[Random().nextInt(sentences.length)]
    }, keyRecto: [], keyVerso: []);
  }

  Sentence getSentence() {
    //TODO: without random, use interval SRS (then ID if equals)
    return sentences[Random().nextInt(sentences.length)];
  }

  @override
  bool isGradeAllowed(Grade grade) { // ATENTION: random = danger
    if (grade == Grade.good || grade == Grade.hard) {
      return false;
    }
    return true;
  }
}