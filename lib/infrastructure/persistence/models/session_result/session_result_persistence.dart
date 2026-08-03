import 'package:psitta/utils/conversion/time_conversion.dart';

import 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

export 'package:psitta/infrastructure/persistence/models/session_result/status_count_persistence.dart';

class SessionResultPersistence {
  final int? id;
  final int uniqueExercisesCompleted;

  final List<StatusCountPersistence> statusCounts;

  final DateTime? startedAt;
  final DateTime? endAt;

  SessionResultPersistence({
    this.id,
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
      uniqueExercisesCompleted: resultRow['number_unique_exercises_completed'] as int,
      statusCounts: statusRows.map(StatusCountPersistence.fromRow).toList(),
      startedAt: safeParseDate(resultRow['started_at'] as String?),
      endAt: safeParseDate(resultRow['end_at'] as String?),
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'number_unique_exercises_completed': uniqueExercisesCompleted,
      'started_at': toIsoUtc(startedAt),
      'end_at': toIsoUtc(endAt),
    };
  }
}
