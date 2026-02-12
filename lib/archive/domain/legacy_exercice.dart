import '../../persistence/database_service.dart';
import '../../utils/convert_utils.dart';
import 'legacy_srs.dart';
import 'legacy_note.dart';

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
  int? id;
  final ExerciceType type;
  final LegacySRSState srsData;
  DateTime? availableAt;

  Exercice({
    this.id,
    required this.type,
    required this.srsData,
    this.availableAt,
  });

  Future<void> saveToDb();

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
  Future<void> saveToDb() async {
    final db = DatabaseService.instance;
    if (id == null) {
      id = await db.insertWordExercice(this);
    } else {
      await db.updateWordExercice(this);
    }
  }
  @override
  Map<String, dynamic> toMap() {
    assert(card.id != null, 'Card must be inserted before WordExercice.');
    return {
      'id': id,
      'type': exerciceTypeToText(type),
      'available_at': toIsoUtc(availableAt),
      'card_id': card.id,
    };
  }

  factory WordExercice.fromMap(Map<String, dynamic> map, Card card, LegacySRSState srsData) {
    return WordExercice(
      id: safeToInt(map['id']),
      card: card,
      srsData: srsData,
      availableAt: safeParseDate(map['available_at'] as String?),
    );
  }
}
