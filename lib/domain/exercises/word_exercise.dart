import 'package:psitta/domain/exercises/exercise.dart';
import 'package:psitta/domain/content/word.dart';

export 'package:psitta/domain/content/word.dart';

/// Classe représentant un exercice de mots.
/// c'est l'exercice de base, equivalent d'un flashcard Anki.
class WordExercise extends Exercise {
  final Word _word;

  WordExercise(this._word, super.status, super.srsState);

  @override
  ExercicePrompt getPrompt() {
    // TODO ?
    return ExercicePrompt(
      promptData: {'word': _word.text},
      keyRecto: [],
      keyVerso: [],
      keyMeta: [],
    );
  }

  @override
  void applyAnswer(RealExerciseAnswer answer, SRSConfig config) {
    // TODO ??
    super.applyAnswer(answer, config);
  }
}
