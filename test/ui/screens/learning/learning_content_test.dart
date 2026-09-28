import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/screens/learning/learning_content.dart';

void main() {
  Widget buildContent({
    required bool showingAnswer,
    required VoidCallback onRevealAnswer,
    required ValueChanged<Grade> onGradeSelected,
    Grade? selectedGrade,
    bool interactionEnabled = true,
    VoidCallback? onToggleSide,
    VoidCallback? onCancelAnswer,
    VoidCallback? onNextExercise,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LearningContent(
          front: const Text('Front content'),
          back: const Text('Back content'),
          showingAnswer: showingAnswer,
          interactionEnabled: interactionEnabled,
          selectedGrade: selectedGrade,
          allowedGrades: const [Grade.again, Grade.good],
          previewIntervals: const {
            Grade.again: Duration.zero,
            Grade.good: Duration(days: 2),
          },
          onRevealAnswer: onRevealAnswer,
          onGradeSelected: onGradeSelected,
          onToggleSide: onToggleSide ?? () {},
          onCancelAnswer: onCancelAnswer ?? () {},
          onNextExercise: onNextExercise ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows the front before revealing the answer', (tester) async {
    var answerRequested = false;

    await tester.pumpWidget(
      buildContent(
        showingAnswer: false,
        onRevealAnswer: () => answerRequested = true,
        onGradeSelected: (_) {},
      ),
    );

    expect(find.text('Question'), findsOneWidget);
    expect(find.text('Front content'), findsOneWidget);
    expect(find.text('Back content'), findsNothing);
    expect(find.text('Again'), findsNothing);

    await tester.tap(find.text('Show answer'));
    expect(answerRequested, isTrue);
  });

  testWidgets('shows the back, intervals, and allowed grades after reveal', (
    tester,
  ) async {
    Grade? selectedGrade;

    await tester.pumpWidget(
      buildContent(
        showingAnswer: true,
        onRevealAnswer: () {},
        onGradeSelected: (grade) => selectedGrade = grade,
      ),
    );

    expect(find.text('Answer'), findsOneWidget);
    expect(find.text('Front content'), findsNothing);
    expect(find.text('Back content'), findsOneWidget);
    expect(find.text('Again'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('2d'), findsOneWidget);
    expect(find.text('Hard'), findsNothing);

    await tester.tap(find.text('Good'));
    expect(selectedGrade, Grade.good);
  });

  testWidgets('keeps the selected answer pending until the next exercise', (
    tester,
  ) async {
    var sideToggled = false;
    var answerCancelled = false;
    var nextRequested = false;

    await tester.pumpWidget(
      buildContent(
        showingAnswer: true,
        selectedGrade: Grade.good,
        onRevealAnswer: () {},
        onGradeSelected: (_) {},
        onToggleSide: () => sideToggled = true,
        onCancelAnswer: () => answerCancelled = true,
        onNextExercise: () => nextRequested = true,
      ),
    );

    expect(find.text('Good selected'), findsOneWidget);
    expect(find.text('Show question'), findsOneWidget);
    expect(find.text('Cancel answer'), findsOneWidget);
    expect(find.text('Next exercise'), findsOneWidget);

    await tester.tap(find.text('Show question'));
    await tester.tap(find.text('Cancel answer'));
    await tester.tap(find.text('Next exercise'));

    expect(sideToggled, isTrue);
    expect(answerCancelled, isTrue);
    expect(nextRequested, isTrue);
  });

  testWidgets('disables the available action while an operation is running', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildContent(
        showingAnswer: false,
        interactionEnabled: false,
        onRevealAnswer: () {},
        onGradeSelected: (_) {},
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('disables pending answer actions while submitting', (tester) async {
    await tester.pumpWidget(
      buildContent(
        showingAnswer: true,
        selectedGrade: Grade.good,
        interactionEnabled: false,
        onRevealAnswer: () {},
        onGradeSelected: (_) {},
      ),
    );

    final outlinedButtons = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    final nextButton = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(outlinedButtons.every((button) => button.onPressed == null), isTrue);
    expect(nextButton.onPressed, isNull);
  });
}
