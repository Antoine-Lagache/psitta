/// One normalized exercise-status count belonging to a session result.
class StatusCountPersistence {
  final int statusCode;
  final int answerCount;

  StatusCountPersistence({required this.statusCode, required this.answerCount});

  factory StatusCountPersistence.fromRow(Map<String, Object?> row) {
    return StatusCountPersistence(
      statusCode: row['status_index'] as int,
      answerCount: row['number_exercise_completed'] as int,
    );
  }

  Map<String, Object?> toRow(int sessionResultId) {
    return {
      'id_session_result': sessionResultId,
      'status_index': statusCode,
      'number_exercise_completed': answerCount,
    };
  }
}
