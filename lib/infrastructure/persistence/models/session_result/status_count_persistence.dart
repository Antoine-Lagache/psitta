/// One normalized exercise-status count belonging to a session result.
class StatusCountPersistence {
  final int statusCode;
  final int exercisesCompleted;

  StatusCountPersistence({required this.statusCode, required this.exercisesCompleted});

  factory StatusCountPersistence.fromRow(Map<String, Object?> row) {
    return StatusCountPersistence(
      statusCode: row['status_index'] as int,
      exercisesCompleted: row['number_exercise_completed'] as int,
    );
  }

  Map<String, Object?> toRow(int sessionResultId) {
    return {
      'id_session_result': sessionResultId,
      'status_index': statusCode,
      'number_exercise_completed': exercisesCompleted,
    };
  }
}
