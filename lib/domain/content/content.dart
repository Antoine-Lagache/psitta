import 'package:psitta/domain/content/field.dart';

/// Class representing the content of an exercise.
class Content {
  final int id;

  final List<Field> fields;

  Content({required this.id, required this.fields});
}
