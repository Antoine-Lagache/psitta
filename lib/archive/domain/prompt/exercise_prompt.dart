import 'package:psitta/domain/content/field.dart';
import 'package:psitta/domain/content/content.dart';

/// Boundary object.
/// Projection of exercise content for UI rendering.
class ExercisePrompt {
  final List<Field> fields;

  ExercisePrompt(this.fields);

  ExercisePrompt.fromContent(Content content) : fields = _filterFields(content.fields);

  static List<Field> _filterFields(List<Field> fields) {
    return fields
        .where((field) => field.definition.renderer != FieldRenderer.none)
        .toList();
  }
}
