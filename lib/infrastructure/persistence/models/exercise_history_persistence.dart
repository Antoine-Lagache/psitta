import 'package:psitta/utils/conversion/time_conversion.dart';

class ExerciseHistoryPersistence {
  final int? id;
  final int exerciseId;
  final int grade;
  final DateTime answeredAt;

  ExerciseHistoryPersistence({
    this.id,
    required this.exerciseId,
    required this.grade,
    required this.answeredAt,
  });

  factory ExerciseHistoryPersistence.fromRow(Map<String, Object?> row) {
    final answeredAt = safeParseDate(row['answered_at'] as String?);

    if (answeredAt == null) {
      throw StateError('Invalid answered_at value: ${row['answered_at']}');
    }
    return ExerciseHistoryPersistence(
      id: row['id'] as int?,
      exerciseId: row['exercise_id'] as int,
      grade: row['grade'] as int,
      answeredAt: answeredAt,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'grade': grade,
      'answered_at': toIsoUtc(answeredAt),
    };
  }
}
