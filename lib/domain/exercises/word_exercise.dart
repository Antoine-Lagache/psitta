import 'answer/exercise_answer.dart';
import '../srs/grade.dart';
import '../srs/srs_config.dart';
import 'exercise.dart';
import '../prompt/exercice_prompt.dart';
import '../content/word.dart';

/// Classe représentant un exercice de mots.
/// c'est l'exercice de base, equivalent d'un flashcard Anki.
class WordExercise extends Exercise {
  final Word word;

  WordExercise(this.word, super.status, super.srsState);

  @override
  ExercicePrompt getPrompt() {
    // TODO ?
    return ExercicePrompt(promptData: {}, keyRecto: [], keyVerso: [], keyMeta: []);
  }

  @override
  void applyAnswer(RealExerciseAnswer answer, SRSConfig config) {
    // TODO ??
    super.applyAnswer(answer, config);
  }
}
