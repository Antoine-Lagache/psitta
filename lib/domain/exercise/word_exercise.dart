import 'package:psitta/domain/exercise/exercise.dart';

/// Represents a single-content flashcard governed directly by the SRS state.
class WordExercise extends Exercise {
  final int contentId;

  WordExercise({
    required this.contentId,
    required super.id,
    required super.status,
    required super.srsState,
  });

  @override
  int getContentId() => contentId;
}
