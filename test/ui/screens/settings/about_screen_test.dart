import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/ui/screens/settings/about_screen.dart';
import 'package:psitta/ui/screens/settings/settings_screen.dart';

void main() {
  testWidgets('opens the About screen from Settings', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Settings will be available in a future update.'), findsOne);

    await tester.tap(find.text('About Psitta'));
    await tester.pumpAndSettle();

    expect(find.text('About Psitta'), findsOne);
    expect(find.text('Created by Antoine Lagache.'), findsOne);
  });

  testWidgets('opens the website and source code links', (tester) async {
    final openedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          linkLauncher: (uri) async {
            openedUris.add(uri);
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Psitta website'));
    await tester.pump();
    await tester.tap(find.text('Source code'));
    await tester.pump();

    expect(
      openedUris,
      equals([
        Uri.parse('https://psitta.net'),
        Uri.parse('https://github.com/Antoine-Lagache/psitta'),
      ]),
    );
  });

  testWidgets('makes a link error selectable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AboutScreen(linkLauncher: (_) async => false)),
    );

    await tester.tap(find.text('Psitta website'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to open link'), findsOne);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText &&
            widget.data?.contains('https://psitta.net') == true,
      ),
      findsOne,
    );
  });

  testWidgets('shows unexpected launch errors without hiding their details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AboutScreen(
          linkLauncher: (_) async => throw StateError('launcher unavailable'),
        ),
      ),
    );

    await tester.tap(find.text('Source code'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText &&
            widget.data?.contains('launcher unavailable') == true,
      ),
      findsOne,
    );
  });
}
