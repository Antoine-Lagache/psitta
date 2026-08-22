class SessionExercisePersistence {
  final int exerciseId;
  final int statusCode;

  final int? trainingCount;

  SessionExercisePersistence({
    required this.exerciseId,
    required this.statusCode,
    this.trainingCount,
  });

  factory SessionExercisePersistence.fromRow(Map<String, Object?> row) {
    return SessionExercisePersistence(
      exerciseId: row['exercise_id'] as int,
      statusCode: row['status_index'] as int,
      trainingCount: row['training_count'] as int?,
    );
  }

  Map<String, Object?> toRow(int sessionResultId) {
    return {
      'session_result_id': sessionResultId,
      'exercise_id': exerciseId,
      'status_index': statusCode,
      'training_count': trainingCount,
    };
  }
}
