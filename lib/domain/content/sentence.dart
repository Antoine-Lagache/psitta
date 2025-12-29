
/// Classe représentant une phrase avec son texte et sa traduction.
/// représente uniquement les données statiques et immuables d'une phrase.
class Sentence {
  final int id;
  final int groupId;
  final String text;
  final String translation;

  Sentence({required this.id, required this.groupId, required this.text, required this.translation});
}