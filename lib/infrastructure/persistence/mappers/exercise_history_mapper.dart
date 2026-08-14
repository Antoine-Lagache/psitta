import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/history/exercise_history_entry.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/infrastructure/persistence/models/exercise_history/exercise_history_persistence.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';

class ExerciseHistoryMapper {
  const ExerciseHistoryMapper();

  static ExerciseHistoryPersistence toPersistence(ExerciseHistoryEntry domain) {
    return ExerciseHistoryPersistence(
      id: domain.id,
      exerciseId: domain.exerciseId,
      sentenceInstanceId: domain.sentenceInstanceId,
      grade: domain.grade.toInt(),
      answeredAt: toIsoUtc(domain.answeredAt)!,
      status: domain.status.code,
    );
  }

  static ExerciseHistoryEntry toDomain(ExerciseHistoryPersistence persistence) {
    return ExerciseHistoryEntry(
      id: persistence.id,
      exerciseId: persistence.exerciseId,
      grade: Grade.fromInt(persistence.grade),
      answeredAt: safeParseDate(persistence.answeredAt)!,
      status: ExerciseStatus.fromCode(persistence.status),
      sentenceInstanceId: persistence.sentenceInstanceId,
    );
  }
}
