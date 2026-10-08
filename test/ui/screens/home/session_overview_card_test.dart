import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/ui/screens/home/session_overview_card.dart';

void main() {
  Widget buildCard({required SessionOverview overview, required VoidCallback onPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: SessionOverviewCard(overview: overview, onPressed: onPressed),
      ),
    );
  }

  testWidgets('displays new-session counts and action', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      buildCard(
        overview: SessionOverview(
          sessionType: SessionType.wordSession,
          newExerciseCount: 6,
          reviewExerciseCount: 4,
          hasActiveSession: false,
        ),
        onPressed: () => pressed = true,
      ),
    );

    expect(find.text('Words'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('To review'), findsOneWidget);
    expect(find.text('Start new session'), findsOneWidget);

    await tester.tap(find.text('Start new session'));
    expect(pressed, isTrue);
  });

  testWidgets('keeps an active session resumable with no remaining counts', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      buildCard(
        overview: SessionOverview(
          sessionType: SessionType.sentenceSession,
          newExerciseCount: 0,
          reviewExerciseCount: 0,
          hasActiveSession: true,
        ),
        onPressed: () => pressed = true,
      ),
    );

    expect(find.text('Sentences'), findsOneWidget);
    expect(find.text('Resume session'), findsOneWidget);

    await tester.tap(find.text('Resume session'));
    expect(pressed, isTrue);
  });

  testWidgets('disables a new session when no exercise is available', (tester) async {
    await tester.pumpWidget(
      buildCard(
        overview: SessionOverview(
          sessionType: SessionType.wordSession,
          newExerciseCount: 0,
          reviewExerciseCount: 0,
          hasActiveSession: false,
        ),
        onPressed: () {},
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
