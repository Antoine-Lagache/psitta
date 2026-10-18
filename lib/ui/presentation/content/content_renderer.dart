import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart' as dom;

import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/ui/presentation/content/audio_control.dart';
import 'package:psitta/ui/presentation/content/field_renderer.dart';

typedef AudioControlBuilder = Widget Function(Uri source);

/// Builds one exercise side by ordering and rendering its visible fields.
class ContentRenderer {
  final FieldRenderer _fieldRenderer;
  final AudioControlBuilder _audioControlBuilder;

  ContentRenderer(this._fieldRenderer, {AudioControlBuilder? audioControlBuilder})
    : _audioControlBuilder = audioControlBuilder ?? _buildAudioControl;

  /// Renders the fields visible on [side] into a single HTML widget.
  Future<Widget> render(Content content, FieldSide side) async {
    final fields = content.fields
        .where(
          (field) =>
              field.definition.side == side || field.definition.side == FieldSide.both,
        )
        .toList();
    _sortFields(fields);

    final fragments = await Future.wait(fields.map(_fieldRenderer.render));

    final html = fragments.join();
    return HtmlWidget(
      html,
      textStyle: const TextStyle(fontFamilyFallback: ['NotoSansJP']),
      customStylesBuilder: _buildReadingStyles,
      customWidgetBuilder: _buildCustomWidget,
    );
  }

  // v0.1 stores presentation sizes inline without semantic CSS classes. Override
  // only the large Japanese reading blocks, including their ruby descendants.
  // Applying this at render time also improves already-installed databases.
  static final _japanese = RegExp(r'[\u3040-\u30ff\u3400-\u9fff]');
  static final _fontSize = RegExp(r'(?:^|;)\s*font-size\s*:\s*(\d+)px');

  Map<String, String>? _buildReadingStyles(dom.Element element) {
    final inlineStyle = element.attributes['style'] ?? '';
    final match = _fontSize.firstMatch(inlineStyle);
    if (match == null || !_japanese.hasMatch(element.text)) {
      return null;
    }
    final size = int.parse(match.group(1)!);
    if (size < 24) {
      return null;
    }
    return {
      'font-family': 'NotoSansJP',
      'font-size': '${(size * 1.2).ceil()}px',
      'font-weight': inlineStyle.contains('font-weight:700') ? '700' : '500',
    };
  }

  Widget? _buildCustomWidget(dom.Element element) {
    if (element.localName != 'audio') {
      return null;
    }

    final source =
        element.attributes['src'] ??
        element.querySelector('source[src]')?.attributes['src'];
    if (source == null || source.isEmpty) {
      return const SizedBox.shrink();
    }
    return _audioControlBuilder(Uri.parse(source));
  }

  static Widget _buildAudioControl(Uri source) {
    return AudioControl(key: ValueKey(source), source: source);
  }

  void _sortFields(List<Field> fields) {
    fields.sort((a, b) {
      final orderComparison = a.displayOrder.compareTo(b.displayOrder);

      if (orderComparison != 0) {
        return orderComparison;
      }

      if (a.id == null && b.id == null) {
        return 0;
      }

      if (a.id == null) {
        return -1;
      }

      if (b.id == null) {
        return 1;
      }

      return a.id!.compareTo(b.id!);
    });
  }
}
