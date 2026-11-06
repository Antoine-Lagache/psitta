import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/models/statistics/exercise_progress_counts.dart';
import 'package:psitta/application/models/statistics/exercise_statistics.dart';
import 'package:psitta/application/models/statistics/session_statistics.dart';
import 'package:psitta/domain/exercise/exercise_status.dart';
import 'package:psitta/ui/screens/statistics/statistics_content.dart';

void main() {
  testWidgets('displays the all-time statistics returned by the controller', (
    tester,
  ) async {
    final sessions = SessionStatistics(
      numberOfSessions: 3,
      numberOfSessionsBySessionType: [2, 1, 0],
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
      numberOfAnswersByGrade: [1, 2, 3, 9],
      numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
      numberOfDistinctExercisesAnswered: 6,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsContent(
            sessionStatistics: sessions,
            exerciseStatistics: exercises,
            todaySessionStatistics: sessions,
            todayExerciseStatistics: exercises,
            progressCounts: const ExerciseProgressCounts(
              notStarted: 60,
              started: 10,
              mastered: 11,
              byType: {
                'word': (notStarted: 10, started: 2, mastered: 1),
                'sentence': (notStarted: 20, started: 3, mastered: 4),
                'character': (notStarted: 30, started: 5, mastered: 6),
              },
            ),
            dailyStreak: 17,
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Sessions completed'), findsNWidgets(2));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('1h 5m'), findsNWidgets(2));
    expect(find.text('Answers recorded'), findsNWidgets(2));
    expect(find.text('17'), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    await tester.tap(find.text('Sections'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exercise progress').last);
    await tester.pumpAndSettle();
    expect(find.text('Words'), findsNWidgets(2));
    expect(find.text('Sentences'), findsNWidgets(2));
    expect(find.text('Kana'), findsNWidgets(2));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('Words'), findsNWidgets(2));
    expect(find.text('Sentences'), findsNWidgets(2));
    expect(find.text('Kana'), findsNWidgets(2));
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Medium'), findsNothing);
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('keeps recorded answers visible without a completed session', (
    tester,
  ) async {
    final sessions = SessionStatistics(
      numberOfSessions: 0,
      numberOfSessionsBySessionType: [0, 0, 0],
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
      numberOfAnswersByGrade: [1, 1, 0, 0],
      numberOfAnswersByStatus: List.filled(ExerciseStatus.values.length, 0),
      numberOfDistinctExercisesAnswered: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsContent(
            sessionStatistics: sessions,
            exerciseStatistics: exercises,
            todaySessionStatistics: sessions,
            todayExerciseStatistics: exercises,
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('0 min'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('Sessions completed'), findsNWidgets(2));
    expect(find.text('Answers recorded'), findsNWidgets(2));
  });
}
