import 'word.dart';
import 'srs.dart';

enum ExerciceType { word }

abstract class Exercice {
  final int id;
  final ExerciceType type;
  SRS srsData;

  Exercice({
    required this.id,
    required this.type,
    required this.srsData,
  });
}

class WordExercice extends Exercice {
  final Word word;

  WordExercice({
    required int id,
    required Word this.word,
    required SRS srsData,
  }) : super(
          id: id,
          type: ExerciceType.word,
          srsData: srsData,
        );
}