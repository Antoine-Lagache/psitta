
/// Classe représentant un mot avec son texte et sa signification.
/// représente uniquement les données statiques et immuables d'un mot.
class Word {
  final int id;
  final String text;
  final String meaning;

  Word({required this.id, required this.text, required this.meaning});
}