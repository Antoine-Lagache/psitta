import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psitta/domain/srs/grade.dart';

/// Displays one side of the current exercise and its available actions.
class LearningContent extends StatelessWidget {
  final Widget front;
  final Widget back;
  final bool showingAnswer;
  final bool interactionEnabled;
  final Grade? selectedGrade;
  final List<Grade> allowedGrades;
  final Map<Grade, Duration> previewIntervals;
  final bool showPreviewIntervals;
  final bool showDrawingArea;
  final VoidCallback onRevealAnswer;
  final ValueChanged<Grade> onGradeSelected;
  final VoidCallback onToggleSide;
  final VoidCallback onCancelAnswer;
  final VoidCallback onNextExercise;

  const LearningContent({
    required this.front,
    required this.back,
    required this.showingAnswer,
    required this.interactionEnabled,
    required this.selectedGrade,
    required this.allowedGrades,
    required this.previewIntervals,
    required this.showPreviewIntervals,
    this.showDrawingArea = false,
    required this.onRevealAnswer,
    required this.onGradeSelected,
    required this.onToggleSide,
    required this.onCancelAnswer,
    required this.onNextExercise,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  children: [_buildCard(context)],
                ),
              ),
            ),
            if (showDrawingArea)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Practice writing',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _KanaWritingArea(key: ValueKey(front)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 280),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSideLabel(context),
              const SizedBox(height: 24),
              Center(child: _buildVisibleSide()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideLabel(BuildContext context) {
    return Text(
      showingAnswer ? 'Answer' : 'Question',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildVisibleSide() {
    return KeyedSubtree(
      key: ValueKey(showingAnswer),
      child: showingAnswer ? back : front,
    );
  }

  Widget _buildActions() {
    if (selectedGrade != null) {
      return _buildSelectedAnswerActions(selectedGrade!);
    }
    if (!showingAnswer) {
      return _buildRevealButton();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 68,
          children: [for (final grade in allowedGrades) _buildGradeButton(grade)],
        );
      },
    );
  }

  Widget _buildRevealButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: interactionEnabled ? onRevealAnswer : null,
        child: const Text('Show answer'),
      ),
    );
  }

  Widget _buildSelectedAnswerActions(Grade grade) {
    return Column(
      children: [
        Text('${_gradeLabel(grade)} selected'),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: interactionEnabled ? onToggleSide : null,
              child: Text(showingAnswer ? 'Show question' : 'Show answer'),
            ),
            OutlinedButton(
              onPressed: interactionEnabled ? onCancelAnswer : null,
              child: const Text('Cancel answer'),
            ),
            FilledButton(
              onPressed: interactionEnabled ? onNextExercise : null,
              child: const Text('Next exercise'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeButton(Grade grade) {
    // Grade colours remain the same in light, dark and Psitta themes.
    final background = switch (grade) {
      Grade.again => const Color(0xFFC62828),
      Grade.hard => const Color(0xFFFFD54F),
      Grade.good => const Color(0xFF2E7D32),
      Grade.easy => const Color(0xFF1565C0),
    };
    final foreground = grade == Grade.hard ? const Color(0xFF212121) : Colors.white;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground.withAlpha(153),
        overlayColor: foreground,
        surfaceTintColor: Colors.transparent,
        side: BorderSide.none,
      ),
      onPressed: interactionEnabled ? () => onGradeSelected(grade) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_gradeLabel(grade)),
            if (showPreviewIntervals) ...[
              const SizedBox(height: 2),
              Text(_formatInterval(_previewIntervalFor(grade))),
            ],
          ],
        ),
      ),
    );
  }

  Duration _previewIntervalFor(Grade grade) {
    return previewIntervals[grade] ??
        (throw StateError('Missing preview interval for ${grade.name}'));
  }

  String _gradeLabel(Grade grade) {
    return switch (grade) {
      Grade.again => 'Again',
      Grade.hard => 'Hard',
      Grade.good => 'Good',
      Grade.easy => 'Easy',
    };
  }

  String _formatInterval(Duration duration) {
    if (duration == Duration.zero) {
      return 'Now';
    }
    if (duration < const Duration(minutes: 1)) {
      return '${duration.inSeconds} sec';
    }
    if (duration < const Duration(hours: 1)) {
      return '${duration.inMinutes} min';
    }
    if (duration < const Duration(days: 1)) {
      final hours = duration.inMinutes / Duration.minutesPerHour;
      return '${hours.toStringAsFixed(1)} ${hours == 1 ? 'hour' : 'hours'}';
    }
    final days = duration.inMinutes / Duration.minutesPerDay;
    return '${days.toStringAsFixed(1)} ${days == 1 ? 'day' : 'days'}';
  }
}

class _KanaWritingArea extends StatefulWidget {
  const _KanaWritingArea({super.key});

  @override
  State<_KanaWritingArea> createState() => _KanaWritingAreaState();
}

class _KanaWritingAreaState extends State<_KanaWritingArea> {
  final List<Offset?> _points = [];

  Offset _normalized(Offset local, Size size) =>
      Offset(local.dx / size.width, local.dy / size.height);

  void _recordPoint(Offset local, Size size) {
    setState(() {
      final bounds = RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(8),
      );
      if (bounds.contains(local)) {
        _points.add(_normalized(local, size));
      } else if (_points.isNotEmpty && _points.last != null) {
        _points.add(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 160);
            return GestureDetector(
              onPanStart: (details) => _recordPoint(details.localPosition, size),
              onPanUpdate: (details) => _recordPoint(details.localPosition, size),
              onPanEnd: (_) => setState(() => _points.add(null)),
              onPanCancel: () => setState(() => _points.add(null)),
              child: CustomPaint(
                key: const ValueKey('character-writing-canvas'),
                size: size,
                painter: _KanaWritingPainter(_points),
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: _points.isEmpty ? null : () => setState(_points.clear),
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}

class _KanaWritingPainter extends CustomPainter {
  final List<Offset?> points;

  _KanaWritingPainter(List<Offset?> points) : points = List.unmodifiable(points);

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final ink = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      border,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
    );
    for (var index = 0; index < points.length - 1; index++) {
      final first = points[index];
      final second = points[index + 1];
      if (first != null && second != null) {
        canvas.drawLine(
          Offset(first.dx * size.width, first.dy * size.height),
          Offset(second.dx * size.width, second.dy * size.height),
          ink,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KanaWritingPainter oldDelegate) =>
      !listEquals(oldDelegate.points, points);
}
