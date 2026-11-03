import 'package:psitta/domain/exercise/exercise.dart';

/// Practices kana recognition and recall using a character or JMdict word card.
class KanaExercise extends Exercise {
  final int contentId;

  KanaExercise({
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
