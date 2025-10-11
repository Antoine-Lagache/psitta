import '../services/convert_utils.dart';
import 'srs.dart';
import 'note.dart';

enum ExerciceType { word }

String exerciceTypeToText(ExerciceType type) {
  switch (type) {
    case ExerciceType.word:
      return 'word';
  }
}

ExerciceType exerciceTypeFromText(String? text) {
  switch (text) {
    case 'word':
      return ExerciceType.word;
    default:
      return ExerciceType.word; // fallback
  }
}

abstract class Exercice {
  final int? id;
  final ExerciceType type;
  final SRSState srsData;
  DateTime? availableAt;

  Exercice({
    this.id,
    required this.type,
    required this.srsData,
    this.availableAt,
  });

  Map<String, dynamic> toMap();
}

class WordExercice extends Exercice {
  final Card card;

  WordExercice({
    super.id,
    required this.card,
    required super.srsData,
    super.availableAt,
  }) : super(
          type: ExerciceType.word,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': exerciceTypeToText(type),
      'available_at': toIsoUtc(availableAt),
      'card_id': card.id,
    };
  }

  factory WordExercice.fromMap(Map<String, dynamic> map, Card card, SRSState srsData) {
    return WordExercice(
      id: safeToInt(map['id']),
      card: card,
      srsData: srsData,
      availableAt: safeParseDate(map['available_at'] as String?),
    );
  }
}
