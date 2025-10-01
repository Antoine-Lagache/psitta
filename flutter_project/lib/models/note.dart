class Note {
  final Map<String, dynamic> data; // JSON flexible
  final List<String>? tags;
  final DateTime createdTime;

  Note({
    required this.data,
    this.tags,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now();
}

class CardTemplate {
  final String rectoHtml;
  final String versoHtml;

  const CardTemplate(
    this.rectoHtml,
    this.versoHtml,
  );
}

class Card {
  final Note note;
  final CardTemplate template;

  const Card(
    this.note,
    this.template
  );
}