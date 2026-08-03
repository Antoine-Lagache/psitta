class StatusCountPersistence {
  final int statusIndex;
  final int exercisesCompleted;

  StatusCountPersistence({required this.statusIndex, required this.exercisesCompleted});

  factory StatusCountPersistence.fromRow(Map<String, Object?> row) {
    return StatusCountPersistence(
      statusIndex: row['status_index'] as int,
      exercisesCompleted: row['number_exercise_completed'] as int,
    );
  }

  Map<String, Object?> toRow(int sessionResultId) {
    return {
      'id_session_result': sessionResultId,
      'status_index': statusIndex,
      'number_exercise_completed': exercisesCompleted,
    };
  }
}
