
class ExercicePrompt {
  final Map<String, dynamic>  promptData;

  /// Listes des clés de la map qui doivent appraitre coté question/ réponse
  /// de l'exercice.
  /// TODO: coté UI ou application: avoir des méthodes Key -> Widget pour chaque clé possible
  final List<String> keyRecto;
  final List<String> keyVerso;

  ExercicePrompt({required this.promptData, required this.keyRecto, required this.keyVerso});
}