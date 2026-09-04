import 'package:psitta/application/models/content/field.dart';

/// Ordered, renderable fields referenced by one or more exercises.
class Content {
  final int? id;

  final List<Field> fields;

  Content({required this.id, required this.fields});
}
