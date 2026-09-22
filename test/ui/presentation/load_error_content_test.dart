import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/ui/presentation/load_error_content.dart';

void main() {
  testWidgets('makes the user message and debug error selectable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadErrorContent(
          message: 'Unable to load statistics.',
          error: StateError('missing column'),
          onRetry: () {},
        ),
      ),
    );

    expect(find.widgetWithText(SelectableText, 'Unable to load statistics.'), findsOne);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.data?.contains('missing column') == true,
      ),
      findsOne,
    );
  });
}
