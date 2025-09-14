
class Word {
  final int id;
  final String languageSrc;
  final String languageDest;

  final String word;
  final String traduction;

  List<String>? examples;
  List<String>? tags;
  DateTime? createdAt;                         

  Word({
    required this.id,
    required this.languageSrc,
    required this.languageDest,
    required this.word,
    required this.traduction,
    this.examples,
    this.tags,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
