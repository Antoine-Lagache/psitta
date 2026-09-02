import 'package:html/dom.dart';

import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';
import 'package:psitta/ui/presentation/content/media_resolver.dart';

/// Converts a typed content field into an HTML fragment.
class FieldRenderer {
  final MediaResolver _mediaResolver;

  FieldRenderer(this._mediaResolver);

  /// Renders [field] according to its declared value type.
  Future<String> render(Field field) {
    return switch (field.definition.valueType) {
      FieldValueType.text => Future.value(_renderText(field)),
      FieldValueType.html => _renderHtml(field),
      FieldValueType.image => Future.value(_renderImage(field)),
      FieldValueType.audio => Future.value(_renderAudio(field)),
      FieldValueType.video => Future.value(_renderVideo(field)),
    };
  }

  String _renderText(Field field) {
    final value = field.value;

    if (value is! TextFieldValue) {
      throw StateError('Expected TextFieldValue for a text field.');
    }

    final fragment = DocumentFragment();
    final lines = value.value.replaceAll('\r\n', '\n').split('\n');

    for (var i = 0; i < lines.length; i++) {
      fragment.append(Text(lines[i]));

      if (i < lines.length - 1) {
        fragment.append(Element.tag('br'));
      }
    }

    return fragment.outerHtml;
  }

  Future<String> _renderHtml(Field field) async {
    final value = field.value;

    if (value is! TextFieldValue) {
      throw StateError('Expected TextFieldValue for an HTML field.');
    }

    return _mediaResolver.resolve(value.value);
  }

  String _renderImage(Field field) {
    final value = field.value;

    if (value is! MediaFieldValue) {
      throw StateError('Expected MediaFieldValue for an image field.');
    }

    return '<img src="${Uri.file(value.media.path)}">';
  }

  String _renderAudio(Field field) {
    final value = field.value;

    if (value is! MediaFieldValue) {
      throw StateError('Expected MediaFieldValue for an audio field.');
    }

    return '<audio src="${Uri.file(value.media.path)}"></audio>';
  }

  String _renderVideo(Field field) {
    final value = field.value;

    if (value is! MediaFieldValue) {
      throw StateError('Expected MediaFieldValue for a video field.');
    }

    return '<video src="${Uri.file(value.media.path)}"></video>';
  }
}
