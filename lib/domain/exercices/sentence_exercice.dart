import '../content/sentence.dart';
import 'exercice.dart';
import '../prompt/exercice_prompt.dart';
import '../srs/grade.dart';
import '../srs/sentence_state.dart';
import '../srs/srs_config.dart';


/// Classe représentant un exercice de phrases. (contient plusieurs phrases)
class SentenceExercice extends Exercice {
  // les 2 listes doivent faire la même taille, chaque phrase a son état associé
  final List<Sentence> sentences = [];
  final List<SentenceState> sentenceStates = [];

  SentenceExercice(super.status, super.srsState); //TODO: constructor

  /// Renvoie un prompt d'une phrase aléatoire pour l'exercice de phrases
  @override
  ExercicePrompt getPrompt() {
    // TODO: use _getSentence, return Prompt of a sentence
    return ExercicePrompt(promptData: {}, keyRecto: [], keyVerso: [],  keyMeta: []);
  }

  // ignore: unused_element
  Sentence _getSentence() {
    //TODO: without random, use sentenceStates (then ID if equals)
    return sentences[0];
  }

  @override
  bool isGradeAllowed(Grade grade) { 
    if (grade == Grade.good || grade == Grade.hard) {
      return false;
    }
    return true;
  }

  @override
  void submitAnswer(Grade grade, DateTime now, SRSConfig config) {
    // TODO: update sentence state too
    super.submitAnswer(grade, now, config);
  }
}