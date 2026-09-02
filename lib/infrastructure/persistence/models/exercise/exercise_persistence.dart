import 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

part 'sentence_exercise_persistence.dart';
part 'word_exercise_persistence.dart';

/// Shared persistence shape for exercise subtypes and their SRS state.
sealed class ExercisePersistence {
  final int? id;
  final SrsStatePersistence srsState;

  String get type => switch (this) {
    WordExercisePersistence() => 'word',
    SentenceExercisePersistence() => 'sentence',
  };

  const ExercisePersistence({this.id, required this.srsState});

  Map<String, Object?> toExerciseRow() {
    return {'id': id, 'type': type};
  }
}
