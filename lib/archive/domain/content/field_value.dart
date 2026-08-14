import 'package:psitta/archive/domain/content/media.dart';

sealed class FieldValue {
  const FieldValue();
}

class TextFieldValue extends FieldValue {
  final String value;

  const TextFieldValue(this.value);
}

class MediaFieldValue extends FieldValue {
  final Media media;

  const MediaFieldValue(this.media);
}
