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
              notStarted: 240,
              started: 325,
              mastered: 585,
              byType: {
                'word': (notStarted: 10, started: 20, mastered: 70),
                'sentence': (notStarted: 210, started: 330, mastered: 460),
                'character': (notStarted: 31, started: 7, mastered: 12),
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

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    final progressSection = find.byKey(const ValueKey('statistics-progress-section'));
    expect(
      find.descendant(of: progressSection, matching: find.text('Words')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('Sentences')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('Kana')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('100')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Show percentages'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: progressSection, matching: find.text('10.0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('20.0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('70.0%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: progressSection, matching: find.text('100.0%')),
      findsNWidgets(3),
    );

    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Completed sessions'), findsOneWidget);
    await tester.tap(find.text('Grades'));
    await tester.pumpAndSettle();
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
