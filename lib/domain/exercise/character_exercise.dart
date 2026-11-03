import 'package:psitta/domain/exercise/exercise.dart';

/// Provides reading and writing practice for a character or word.
class CharacterExercise extends Exercise {
  final int contentId;

  CharacterExercise({
    required this.contentId,
    required super.id,
    required super.status,
    required super.srsState,
    super.trainingCountMax,
    super.trainingCount,
  });

  @override
  int getContentId() => contentId;
}
