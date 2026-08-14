import 'package:psitta/domain/exercise/exercise.dart';

/// Represents a word exercise, which is the basic exercise equivalent to an Anki flashcard.
class WordExercise extends Exercise {
  final int contentId;

  @override
  int getContentId() => contentId;

  WordExercise({
    required this.contentId,
    required super.id,
    required super.status,
    required super.srsState,
  });

  @override
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    newHistoryEntry.add(
      ExerciseHistoryEntry.fromAnswer(answer: answer, exerciseId: id, status: status),
    );
    super.applyAnswer(answer, config);
  }
}
