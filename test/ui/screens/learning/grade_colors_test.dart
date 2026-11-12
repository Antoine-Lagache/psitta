import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/screens/learning/learning_content.dart';
import 'package:psitta/ui/theme/app_theme.dart';

void main() {
  for (final theme in AppThemeVariant.values) {
    testWidgets('grade colours and actions are stable in ${theme.name}', (tester) async {
      const colours = {
        Grade.again: Color(0xFFC62828),
        Grade.hard: Color(0xFFFFD54F),
        Grade.good: Color(0xFF2E7D32),
        Grade.easy: Color(0xFF1565C0),
      };
      const labels = {
        Grade.again: 'Again',
        Grade.hard: 'Hard',
        Grade.good: 'Good',
        Grade.easy: 'Easy',
      };
      Grade? selected;
      Widget buildContent({required bool enabled}) {
        return MaterialApp(
          theme: buildAppTheme(variant: theme),
          home: Scaffold(
            body: LearningContent(
              front: const Text('Front'),
              back: const Text('Back'),
              showingAnswer: true,
              interactionEnabled: enabled,
              selectedGrade: null,
              allowedGrades: Grade.values,
              previewIntervals: const {},
              showPreviewIntervals: false,
              onRevealAnswer: () {},
              onGradeSelected: (grade) => selected = grade,
              onToggleSide: () {},
              onCancelAnswer: () {},
              onNextExercise: () {},
            ),
          ),
        );
      }

      await tester.pumpWidget(buildContent(enabled: true));
      await tester.pumpAndSettle();
      for (final grade in Grade.values) {
        final finder = find.widgetWithText(OutlinedButton, labels[grade]!);
        final button = tester.widget<OutlinedButton>(finder);
        final style = button.style!;
        expect(style.backgroundColor!.resolve({}), colours[grade]);
        final foreground = style.foregroundColor!.resolve({})!;
        final background = colours[grade]!;
        final light = foreground.computeLuminance();
        final dark = background.computeLuminance();
        final contrast = light > dark
            ? (light + 0.05) / (dark + 0.05)
            : (dark + 0.05) / (light + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
        await tester.tap(finder);
        expect(selected, grade);
      }

      await tester.pumpWidget(buildContent(enabled: false));
      await tester.pumpAndSettle();
      selected = null;
      for (final grade in Grade.values) {
        final finder = find.widgetWithText(OutlinedButton, labels[grade]!);
        final button = tester.widget<OutlinedButton>(finder);
        expect(button.onPressed, isNull);
        expect(
          button.style!.backgroundColor!.resolve({WidgetState.disabled}),
          colours[grade],
        );
        await tester.tap(finder);
      }
      expect(selected, isNull);
    });
  }
}
