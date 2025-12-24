import 'exercice.dart';
import '../prompt/exercice_prompt.dart';
import '../content/word.dart';

class WordExercice extends Exercice {
  final Word word;

  WordExercice(this.word, super.status, super.srsState);


  @override
  ExercicePrompt getPrompt() {
    return ExercicePrompt(promptData: {
      'word': word.text,
      'definition': word.meaning
    }, keyRecto: [], keyVerso: []);
  }

}