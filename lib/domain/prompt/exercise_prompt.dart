import 'package:psitta/domain/content/field.dart';

/// Boundary object
/// Class representing the prompt for an exercise.
/// It is a projection of the exercise data for the UI.
class ExercisePrompt {
  final List<Field> fields;

  ExercisePrompt(this.fields);

  ExercisePrompt.fromFields(List<Field> fields) : fields = _filterFields(fields);

  static List<Field> _filterFields(List<Field> fields) {
    return fields.where((field) => field.tags.contains('displayable')).toList();
  }
}
