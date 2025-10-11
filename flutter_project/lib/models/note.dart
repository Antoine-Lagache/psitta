import '../services/convert_utils.dart';

class Note {
  final int? id;
  final Map<String, dynamic> data; // JSON flexible
  final List<String> tags;
  final DateTime createdTime;

  Note({
    this.id,
    required this.data,
    this.tags = const [],
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': safeJsonEncode(data) ?? "",   // encode propre
      'tags': safeJsonEncode(tags),
      'created_time': toIsoUtc(createdTime),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: safeToInt(map['id']),
      data: safeJsonDecodeMap(map['data'] as String?),
      tags: safeJsonDecodeStringList(map["tags"] as String?),
      createdTime: safeParseDate(map['created_time'] as String) ?? DateTime.now(),
    );
  }
}

class CardTemplate {
  final int? id;
  final String rectoHtml;
  final String versoHtml;

  const CardTemplate(
    this.id,
    this.rectoHtml,
    this.versoHtml,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recto_html': rectoHtml,
      'verso_html': versoHtml,
    };
  }

  factory CardTemplate.fromMap(Map<String, dynamic> map) {
    return CardTemplate(
      safeToInt(map['id']),
      map['recto_html'] as String,
      map['verso_html'] as String,
    );
  }
}

class Card {
  final int? id;
  final Note note;
  final CardTemplate template;

  const Card(
    this.id,
    this.note,
    this.template
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': note.id,
      'template_id': template.id,
    };
  }

  factory Card.fromMap(Map<String, dynamic> map, Note note, CardTemplate template) {
    return Card(
      safeToInt(map['id']),
      note,
      template,
    );
  }
}