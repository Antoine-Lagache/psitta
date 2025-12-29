import 'exercice.dart';
import '../prompt/exercice_prompt.dart';
import '../content/word.dart';

/// Classe représentant un exercice de mots.
/// c'est l'exercice de base, equivalent d'un flashcard Anki.
class WordExercice extends Exercice {
  final Word word;

  WordExercice(this.word, super.status, super.srsState);


  @override
  ExercicePrompt getPrompt() {
    return ExercicePrompt(promptData: {}, keyRecto: [], keyVerso: [],  keyMeta: []);
  }

}