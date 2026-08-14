import 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

class SessionResultPersistence {
  final int? id;
  final int sessionTypeIndex;

  final int uniqueExercisesCompleted;
  final List<StatusCountPersistence> statusCounts;

  final String? startedAt;
  final String? endAt;

  SessionResultPersistence({
    this.id,
    required this.sessionTypeIndex,
    required this.uniqueExercisesCompleted,
    required this.statusCounts,
    this.startedAt,
    this.endAt,
  });

  factory SessionResultPersistence.fromRow(
    Map<String, Object?> resultRow,
    List<Map<String, Object?>> statusRows,
  ) {
    return SessionResultPersistence(
      id: resultRow['id'] as int?,
      sessionTypeIndex: resultRow['session_type_index'] as int,
      uniqueExercisesCompleted: resultRow['number_unique_exercises_completed'] as int,
      statusCounts: statusRows.map(StatusCountPersistence.fromRow).toList(),
      startedAt: resultRow['started_at'] as String?,
      endAt: resultRow['end_at'] as String?,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'session_type_index': sessionTypeIndex,
      'number_unique_exercises_completed': uniqueExercisesCompleted,
      'started_at': startedAt,
      'end_at': endAt,
    };
  }
}
