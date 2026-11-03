import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/exercise.dart';
import 'package:psitta/domain/exercise/kana_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:test/test.dart';

void main() {
  group('Exercise training', () {
    test('the shared consolidation phase does not update FSRS and counts successes', () {
      final exercise = KanaExercise(
        contentId: 1,
        id: 1,
        status: ExerciseStatus.consolidating,
        srsState: SRSState(),
        trainingCountMax: 1,
      );
      final originalSrsState = exercise.srsState;
      final answeredAt = DateTime.utc(2026, 11, 3, 12);

      exercise.applyAnswer(
        SubmittedExerciseAnswer(grade: Grade.again, answeredAt: answeredAt),
        SRSConfig(),
      );

      expect(exercise.trainingCount, 1);
      expect(exercise.status, ExerciseStatus.consolidating);
      expect(exercise.srsState, same(originalSrsState));
      expect(exercise.newHistoryEntry, hasLength(1));

      exercise.applyAnswer(
        SubmittedExerciseAnswer(grade: Grade.good, answeredAt: answeredAt),
        SRSConfig(),
      );

      expect(exercise.trainingCount, 0);
      expect(exercise.status, ExerciseStatus.completed);
      expect(exercise.srsState, same(originalSrsState));
      expect(exercise.newHistoryEntry, hasLength(2));
    });

    test('word exercises cannot configure additional training', () {
      final exercise = WordExercise(
        contentId: 1,
        id: 1,
        status: ExerciseStatus.newExercise,
        srsState: SRSState(),
      );

      expect(exercise.trainingCountMax, 0);
      expect(exercise.trainingCount, 0);
    });
  });
}
