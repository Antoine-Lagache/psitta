import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/session/session_overview.dart';
import 'package:psitta/application/startup/content_release_state.dart';
import 'package:psitta/application/models/session/start_session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/screens/home/home_screen.dart';
import 'package:psitta/ui/screens/home/session_overview_card.dart';
import 'package:psitta/ui/screens/learning/learning_screen.dart';

void main() {
  for (final type in [SessionType.wordSession, SessionType.sentenceSession]) {
    testWidgets('import completes safely during a $type session', (tester) async {
      final controller = _TransitionSessionController();
      final importing = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              sessionController: controller,
              contentRenderer: _TestContentRenderer(),
              contentReleaseState: ContentReleaseState(importing.future),
            ),
          ),
        ),
      );
      await tester.pump();
      Finder card(SessionType type) => find.byWidgetPredicate(
        (widget) => widget is SessionOverviewCard && widget.overview.sessionType == type,
      );
      Finder button(SessionType type) =>
          find.descendant(of: card(type), matching: find.byType(FilledButton));
      await tester.scrollUntilVisible(card(SessionType.characterSession), 300);
      await tester.pump();
      expect(find.text('Loading character exercises…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(button(SessionType.characterSession)).onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(button(type), -300);
      await tester.pump();
      await tester.tap(button(type));
      await tester.pumpAndSettle();
      expect(controller.started, [type]);
      expect(find.byType(LearningScreen), findsOneWidget);

      controller.imported = true;
      importing.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(LearningScreen), findsOneWidget);
      expect(controller.hasActiveSession, isTrue);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Pause session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause session').last);
      controller.finishPause.complete();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(card(SessionType.characterSession), 300);
      await tester.pumpAndSettle();
      expect(find.text('Loading character exercises…'), findsNothing);
      expect(
        tester.widget<FilledButton>(button(SessionType.characterSession)).onPressed,
        isNotNull,
      );
      await tester.tap(button(SessionType.characterSession));
      await tester.pumpAndSettle();
      expect(controller.started, [type, SessionType.characterSession]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed import displays an error and keeps kana disabled', (tester) async {
    final importing = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            sessionController: _TransitionSessionController(),
            contentRenderer: _TestContentRenderer(),
            contentReleaseState: ContentReleaseState(importing.future),
          ),
        ),
      ),
    );
    await tester.pump();
    importing.completeError(StateError('Import failed'));
    await tester.pumpAndSettle();
    final card = find.byWidgetPredicate(
      (widget) =>
          widget is SessionOverviewCard &&
          widget.overview.sessionType == SessionType.characterSession,
    );
    await tester.scrollUntilVisible(card, 300);
    await tester.pumpAndSettle();
    expect(
      find.text('Character exercises could not be loaded. Restart the app to try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(of: card, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TransitionSessionController implements SessionController {
  bool _active = false;
  final Completer<void> finishPause = Completer<void>();
  bool imported = false;
  final started = <SessionType>[];

  @override
  Future<List<SessionOverview>> getSessionOverviews() async => [
    for (final type in SessionType.values)
      SessionOverview(
        sessionType: type,
        newExerciseCount: type == SessionType.characterSession && !imported ? 0 : 5,
        reviewExerciseCount: 0,
        hasActiveSession: false,
      ),
  ];

  @override
  bool get hasActiveSession => _active;

  @override
  Future<StartSessionResult> startNewSession(SessionType type) async {
    started.add(type);
    _active = true;
    return StartSessionResult.started;
  }

  @override
  Future<Content> getCurrentExerciseContent() async => Content(id: 1, fields: []);

  @override
  int get remainingExerciseCount {
    if (!_active) throw StateError('A session must be active first');
    return 1;
  }

  @override
  int get remainingTrainingCount {
    if (!_active) throw StateError('A session must be active first');
    return 0;
  }

  @override
  List<Grade> getCurrentExerciseAllowedGrade() => [Grade.good];

  @override
  bool get currentExerciseHasPreviewInterval => false;

  @override
  bool get currentExerciseHasDrawingArea => false;

  @override
  Future<void> pauseSession() {
    _active = false;
    return finishPause.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestContentRenderer implements ContentRenderer {
  @override
  Future<Widget> render(Content content, FieldSide side) async =>
      Text(side == FieldSide.front ? 'Front' : 'Back');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
