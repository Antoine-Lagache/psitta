import 'exercice.dart';
import 'srs.dart';

class Session {
  final List<Exercice> toDo; // liste simple, pas de timer
  final List<Exercice> inProgress = []; // maintenue triée par availableAt asc
  final List<Exercice> completed = [];

  final SRSConfig config;
  String sessionType; //inutilisé pour l'instant

  Session(List<Exercice> newList, List<Exercice> dueList, this.config, {this.sessionType = "Default"})
    : toDo = []
    {
      _initSession(newList, dueList);
    }

  // helper: insert en maintenant la liste triée par availableAt
  void _addToInProgressSorted(Exercice exo) {  //bien
    // retire une occurrence existante pour éviter les doublons
    inProgress.remove(exo);
    if (exo.availableAt == null) {
      // si pas de time, on le met à la fin
      inProgress.add(exo);
      return;
    }
    final idx = inProgress.indexWhere((e) =>
        e.availableAt == null || e.availableAt!.isAfter(exo.availableAt!));
    if (idx == -1) {
      inProgress.add(exo);
    } else {
      inProgress.insert(idx, exo);
    }
  }

  /// choisi l'exercice suivant :
  /// - si un item inProgress est dispo (availableAt <= now) on le prend (le plus tôt)
  /// - sinon on prend le premier de toDo (s'il en reste)
  Exercice? chooseExercice() {
    final now = DateTime.now().toUtc();
    // chercher le premier inProgress si disponible
    if (inProgress.isNotEmpty && (inProgress[0].availableAt == null || inProgress[0].availableAt!.isBefore(now))){
      return inProgress.removeAt(0);
    }  
    if (toDo.isNotEmpty) { //sinon commencer un autre exercice
      return toDo.removeAt(0);
    }
    if(inProgress.isNotEmpty){ //finir les exercice commencé si toDo est vide
      return inProgress.removeAt(0);
    }
    return null; // rien dispo
  }
  ///Renvoie true si toDo ou inProgress non vide.
  bool hasNext(){
    return toDo.isNotEmpty || inProgress.isNotEmpty;
  }

  /// submitAnswer applique toujours update SRS puis gère learning steps.
void submitAnswer(Exercice exo, int grade) {
    inProgress.remove(exo);
    final bool wasLearning = exo.srsData.learningStepIndex >= 0;
    Duration res;
    if (wasLearning) {
      res = exo.srsData.applyLearningAnswer(grade, config, steps: config.learningSteps);
    } else {
      res = exo.srsData.applyReviewAnswer(grade, config);
    }

    // decide placement based on day boundary
    final DateTime now = DateTime.now().toUtc();
    DateTime boundary = DateTime.utc(now.year, now.month, now.day).add(config.dayBoundary);
    if (boundary.isBefore(now)){
      boundary = boundary.add(Duration(days: 1));
    }
    // if availableAt before boundary (i.e. still today) -> keep in inProgress
    if (now.add(res).isBefore(boundary)) {
      exo.availableAt = now.add(res);
      _addToInProgressSorted(exo);
    }else{
      exo.availableAt = now.add(res);
      exo.availableAt = DateTime.utc(exo.availableAt!.year, exo.availableAt!.month, exo.availableAt!.day).add(config.dayBoundary);
      completed.add(exo);
    }
  }

  Duration getPreviewInterval(Exercice exo, int q){
    if (exo.srsData.learningStepIndex >=0){
      return exo.srsData.computePreviewLearning(q, config, steps:config.learningSteps);
    }
    return exo.srsData.computePreviewReview(q, config);
  }

  /// Initialise les listes internes de la session.
  /// - Sépare les exercices dus entre `inProgress` (déjà commencés) et `toDo` (à réviser),
  /// - Mélange et intercale les nouveaux exercices avec ceux à réviser.
  void _initSession(List<Exercice> dueList, List<Exercice> newList) {
    // Nettoyer les listes actuelles avant toute reconstruction
    toDo.clear();
    inProgress.clear();

    // Helper pour comparer les dates "même jour"
    bool sameDay(DateTime? a, DateTime? b) {
      if (a == null || b == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    // Séparer les exercices en fonction de leurs dates
    for (final exo in dueList) {
      final srs = exo.srsData;
      if (sameDay(srs.lastReview, srs.nextReview)) {
        inProgress.add(exo); // exercice déjà vu aujourd’hui
      } else {
        toDo.add(exo); // à réviser normalement
      }
    }

    // Mélange les listes
    toDo.shuffle();
    newList.shuffle();

    // Répartition des nouveaux exercices au milieu des révisions
    final N = toDo.length;
    final M = newList.length;

    if (M == 0) return; // aucune carte nouvelle, pas besoin de réordonner
    if (N == 0) {
      toDo.addAll(newList);
      return;
    }

    var chunkSize = (N / M).floor();
    if (chunkSize < 1) chunkSize = 1;
    final mixedOrder = <Exercice>[];

    var indexDue = 0;
    var indexNew = 0;

    while (indexDue < N || indexNew < M) {
      // Ajouter un bloc de révisions
      for (var i = 0; i < chunkSize && indexDue < N; i++) {
        mixedOrder.add(toDo[indexDue]);
        indexDue++;
      }
      
      // Ajouter un nouveau mot
      if (chunkSize == 1){
        for (var i = 0; i < (M/N).floor() && indexNew < M; i++) {
          mixedOrder.add(newList[indexDue]);
          indexNew++;
        }
      }else {
        if (indexNew < M) {
          mixedOrder.add(newList[indexNew]);
          indexNew++;
        }
      }
    }

    // Met à jour la liste finale "toDo"
    toDo
      ..clear()
      ..addAll(mixedOrder);
  }
}