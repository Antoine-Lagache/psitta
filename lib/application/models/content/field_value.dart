import 'package:psitta/application/models/content/media.dart';

/// Value payload supported by a content field.
sealed class FieldValue {
  const FieldValue();
}

/// Text payload used for plain-text and HTML field definitions.
class TextFieldValue extends FieldValue {
  final String value;

  const TextFieldValue(this.value);
}

/// Media payload used for image, audio, and video field definitions.
class MediaFieldValue extends FieldValue {
  final Media media;

  const MediaFieldValue(this.media);
}
