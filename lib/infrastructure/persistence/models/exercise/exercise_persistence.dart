import 'package:psitta/utils/conversion/time_conversion.dart';

import 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/exercise/srs_state_persistence.dart';
export 'package:psitta/utils/conversion/time_conversion.dart';

part 'sentence_exercise_persistence.dart';
part 'word_exercise_persistence.dart';

sealed class ExercisePersistence {
  final int? id;
  final DateTime createdAt;
  final SrsStatePersistence srsState;

  String get type => switch (this) {
    WordExercisePersistence() => 'word',
    SentenceExercisePersistence() => 'sentence',
  };

  const ExercisePersistence({this.id, required this.createdAt, required this.srsState});

  static DateTime parseCreatedAt(Map<String, Object?> row) {
    final createdAt = safeParseDate(row['created_at'] as String?);

    if (createdAt == null) {
      throw StateError('Invalid created_at value: ${row['created_at']}');
    }

    return createdAt;
  }

  Map<String, Object?> toExerciseRow() {
    return {'id': id, 'type': type, 'created_at': toIsoUtc(createdAt)};
  }
}
