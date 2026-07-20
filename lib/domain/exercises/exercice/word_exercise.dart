import 'package:psitta/domain/exercises/exercice/exercise.dart';
import 'package:psitta/domain/content/content.dart';

/// Represents a word exercise, which is the basic exercise equivalent to an Anki flashcard.
class WordExercise extends Exercise {
  final Content content;

  WordExercise(this.content, {required super.status, required super.srsState});

  @override
  ExercisePrompt getPrompt() {
    return ExercisePrompt.fromFields(content.fields);
  }
}
