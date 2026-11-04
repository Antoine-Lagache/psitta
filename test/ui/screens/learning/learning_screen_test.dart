import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/application/controllers/session_controller.dart';
import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/session/start_session_result.dart';
import 'package:psitta/domain/sessions/session_type.dart';
import 'package:psitta/domain/srs/grade.dart';
import 'package:psitta/ui/presentation/content/content_renderer.dart';
import 'package:psitta/ui/screens/learning/learning_screen.dart';

void main() {
  testWidgets('pausing never rebuilds an exercise after its session is cleared', (
    tester,
  ) async {
    final controller = _TransitionSessionController();
    final renderer = _TestContentRenderer();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => LearningScreen(
                    sessionController: controller,
                    contentRenderer: renderer,
                    sessionType: SessionType.wordSession,
                    resumeSession: false,
                  ),
                ),
              ),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Question'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause session').last);
    await tester.pump();

    // Simulate a pause that has invalidated the session but has not yet
    // completed its asynchronous persistence/navigation transition.
    expect(controller.hasActiveSession, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A parent rebuild must not query counters from the cleared session.
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.finishPause.complete();
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TransitionSessionController implements SessionController {
  bool _active = false;
  final Completer<void> finishPause = Completer<void>();

  @override
  bool get hasActiveSession => _active;

  @override
  Future<StartSessionResult> startNewSession(SessionType type) async {
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
