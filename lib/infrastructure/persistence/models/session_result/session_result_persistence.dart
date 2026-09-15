import 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

/// Database representation of a session aggregate and its status counts.
class SessionResultPersistence {
  final int? id;
  final int sessionTypeIndex;

  final int uniqueExercisesCompleted;
  final List<StatusCountPersistence> statusCounts;
  final int totalTimeSpent;

  final String? startedAt;
  final String? endAt;

  SessionResultPersistence({
    this.id,
    required this.sessionTypeIndex,
    required this.uniqueExercisesCompleted,
    required this.statusCounts,
    required this.totalTimeSpent,
    this.startedAt,
    this.endAt,
  });

  factory SessionResultPersistence.fromRow(
    Map<String, Object?> resultRow,
    List<Map<String, Object?>> statusRows, {
    List<Map<String, Object?>>? exerciseRows,
  }) {
    return SessionResultPersistence(
      id: resultRow['id'] as int?,
      sessionTypeIndex: resultRow['session_type_index'] as int,
      uniqueExercisesCompleted: resultRow['number_unique_exercises_completed'] as int,
      statusCounts: statusRows.map(StatusCountPersistence.fromRow).toList(),
      totalTimeSpent: resultRow['total_time_spent_us'] as int,
      startedAt: resultRow['started_at'] as String?,
      endAt: resultRow['end_at'] as String?,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'session_type_index': sessionTypeIndex,
      'number_unique_exercises_completed': uniqueExercisesCompleted,
      'total_time_spent_us': totalTimeSpent,
      'started_at': startedAt,
      'end_at': endAt,
    };
  }
}
