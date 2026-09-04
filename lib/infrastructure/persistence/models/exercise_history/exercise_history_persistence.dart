/// Database-safe representation of one immutable answer event.
class ExerciseHistoryPersistence {
  final int? id;
  final int exerciseId;
  final int? sentenceInstanceId;

  final int grade;
  final String answeredAt;
  final int status;

  ExerciseHistoryPersistence({
    this.id,
    required this.exerciseId,
    this.sentenceInstanceId,
    required this.grade,
    required this.answeredAt,
    required this.status,
  });

  factory ExerciseHistoryPersistence.fromRow(Map<String, Object?> row) {
    return ExerciseHistoryPersistence(
      id: row['id'] as int?,
      exerciseId: row['exercise_id'] as int,
      sentenceInstanceId: row['sentence_instance_id'] as int?,
      grade: row['grade'] as int,
      answeredAt: row['answered_at'] as String,
      status: row['status'] as int,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'sentence_instance_id': sentenceInstanceId,
      'grade': grade,
      'answered_at': answeredAt,
      'status': status,
    };
  }
}
