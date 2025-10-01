import 'srs.dart';
import 'note.dart';

enum ExerciceType { word }

abstract class Exercice {
  final ExerciceType type;
  SRSState srsData;

  DateTime? availableAt;   // moment où l'exercice redevient disponible. null au départ
  
  Exercice({
    required this.type,
    required this.srsData,
  });
}

class WordExercice extends Exercice {
  final Card card;

  WordExercice({
    required this.card,
    required super.srsData,
  }) : super(
          type: ExerciceType.word
        );
}