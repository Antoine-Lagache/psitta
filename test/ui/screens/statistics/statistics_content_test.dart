import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/screens/statistics/statistics_content.dart';

void main() {
  testWidgets(
    'displays the all-time statistics returned by the controller',
    (tester) async {
      final sessions = SessionStatistics(
        numberOfSessions: 3,
        numberOfSessionsBySessionType: [2, 1],
        numberOfAnswers: 15,
        numberOfExercisesCompleted: 4,
        numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
        totalTimeSpent: const Duration(hours: 1, minutes: 5),
        numberOfTimedSessions: 3,
        averageTimePerSession: const Duration(minutes: 21, seconds: 40),
        averageNumberOfAnswersPerSession: 5,
      );
      final exercises = ExerciseStatistics(
        totalNumberAnswers: 15,
        numberOfAnswersByGrade: [1, 2, 3, 4, 5],
        numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
        numberOfDistinctExercisesAnswered: 6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsContent(
              sessionStatistics: sessions,
              exerciseStatistics: exercises,
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Sessions completed'), findsOneWidget);
      expect(find.text('1h 5m'), findsOneWidget);
      expect(find.text('Answers recorded'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Sentences'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps recorded answers visible without a completed session',
    (tester) async {
      final sessions = SessionStatistics(
        numberOfSessions: 0,
        numberOfSessionsBySessionType: [0, 0],
        numberOfAnswers: 0,
        numberOfExercisesCompleted: 0,
        numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
        totalTimeSpent: Duration.zero,
        numberOfTimedSessions: 0,
        averageTimePerSession: Duration.zero,
        averageNumberOfAnswersPerSession: 0,
      );
      final exercises = ExerciseStatistics(
        totalNumberAnswers: 2,
        numberOfAnswersByGrade: [1, 1, 0, 0, 0],
        numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
        numberOfDistinctExercisesAnswered: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatisticsContent(
              sessionStatistics: sessions,
              exerciseStatistics: exercises,
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Sessions completed'), findsOneWidget);
      expect(find.text('Answers recorded'), findsOneWidget);
    },
  );
}
