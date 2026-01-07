
/// Objet Boundary
/// Classe représentant le prompt d'un exercice.
/// Contient les données à afficher et les clés pour chaque coté de l'exercice.
/// c'est une projection des données de l'exercice pour l'UI.
class ExercicePrompt {
  final Map<String, dynamic>  promptData;

  /// Listes des clés de la map qui doivent appraitre coté question/ réponse
  /// de l'exercice.
  /// TODO: coté UI ou application: avoir des méthodes Key -> Widget pour chaque clé possible
  /// la liste de toutes les clés possible devra etre fixée et définie.
  final List<String> keyRecto;
  final List<String> keyVerso;
  final List<String> keyMeta;

  ExercicePrompt({required this.promptData, required this.keyRecto, required this.keyVerso, required this.keyMeta});
}