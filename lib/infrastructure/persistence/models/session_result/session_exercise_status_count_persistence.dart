/// Number of exercise snapshots in one persisted session status.
class SessionExerciseStatusCountPersistence {
  final int statusCode;
  final int exerciseCount;

  SessionExerciseStatusCountPersistence({
    required this.statusCode,
    required this.exerciseCount,
  });

  factory SessionExerciseStatusCountPersistence.fromRow(Map<String, Object?> row) {
    return SessionExerciseStatusCountPersistence(
      statusCode: row['status_index'] as int,
      exerciseCount: row['exercise_count'] as int,
    );
  }
}
