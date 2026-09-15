import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/sentences/sentence_instance.dart';
import 'package:psitta/domain/sessions/session.dart';
import 'package:psitta/domain/srs/sentence_state.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';
import 'package:test/test.dart';

void main() {
  group('Session', () {
    test('an invalid sentence grade does not mutate domain state', () {
      final sentenceState = SentenceState();
      final exercise = SentenceExercise(
        sentences: SentenceGroup(
          id: 1,
          sentences: [
            SentenceInstance(id: 1, contentId: 1, state: sentenceState),
          ],
        ),
        trainingCountMax: 1,
        id: 1,
        status: ExerciseStatus.newExercise,
        srsState: SRSState(),
      );
      final session = Session(
        exercises: [exercise],
        sessionType: SessionType.sentenceSession,
        config: SRSConfig(),
      );
      final startedAt = DateTime.utc(2026, 9, 14, 10);
      session.beginSession(startedAt);

      expect(
        () => session.submitAnswer(
          SubmittedExerciseAnswer(grade: Grade.hard, answeredAt: startedAt),
        ),
        throwsStateError,
      );

      expect(exercise.newHistoryEntry, isEmpty);
      expect(exercise.status, ExerciseStatus.newExercise);
      expect(sentenceState.shownCount, 0);
      expect(
        session.intermediateResult.getNumberOfAnswersByStatus(
          ExerciseStatus.newExercise,
        ),
        0,
      );
    });

    test('an invalid sentence preview does not mutate domain state', () {
      final sentenceState = SentenceState();
      final exercise = SentenceExercise(
        sentences: SentenceGroup(
          id: 1,
          sentences: [
            SentenceInstance(id: 1, contentId: 1, state: sentenceState),
          ],
        ),
        trainingCountMax: 1,
        id: 1,
        status: ExerciseStatus.newExercise,
        srsState: SRSState(),
      );
      final session = Session(
        exercises: [exercise],
        sessionType: SessionType.sentenceSession,
        config: SRSConfig(),
      );
      final now = DateTime.utc(2026, 9, 14, 10);
      session.beginSession(now);

      expect(
        () => session.getPreviewInterval(
          PreviewExerciseAnswer(grade: Grade.easy, at: now),
        ),
        throwsStateError,
      );
      expect(sentenceState.shownCount, 0);
      expect(exercise.newHistoryEntry, isEmpty);
    });

    test('accumulates only non-negative measured durations', () {
      final exercise = SentenceExercise(
        sentences: SentenceGroup(
          id: 1,
          sentences: [
            SentenceInstance(id: 1, contentId: 1, state: SentenceState()),
          ],
        ),
        trainingCountMax: 1,
        id: 1,
        status: ExerciseStatus.newExercise,
        srsState: SRSState(),
      );
      final session = Session(
        exercises: [exercise],
        sessionType: SessionType.sentenceSession,
        config: SRSConfig(),
      );
      session.beginSession(DateTime.utc(2026, 9, 14, 10));

      session.addTimeSpent(const Duration(minutes: 2));
      session.addTimeSpent(const Duration(seconds: 30));

      expect(
        session.intermediateResult.totalTimeSpent,
        const Duration(minutes: 2, seconds: 30),
      );
      expect(
        () => session.addTimeSpent(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });
}
