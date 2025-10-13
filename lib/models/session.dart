import 'exercice.dart';
import 'srs.dart';

class Session {
  final List<Exercice> toDo; // liste simple, pas de timer
  final List<Exercice> inProgress = []; // maintenue triée par availableAt asc
  final List<Exercice> completed = [];

  final SRSConfig config;
  String sessionType; //inutilisé pour l'instant

  Session(List<Exercice> newList, List<Exercice> dueList, this.config, {this.sessionType = "Default"})
      : toDo = buildSessionOrder(newList, dueList);

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
      completed.add(exo);
    }
  }

  Duration getPreviewInterval(Exercice exo, int q){
    if (exo.srsData.learningStepIndex >=0){
      return exo.srsData.computePreviewLearning(q, config, steps:config.learningSteps);
    }
    return exo.srsData.computePreviewReview(q, config);
  }

  /// dueList : liste de mots à réviser, newList : liste de nouveaux mots.
  static List<Exercice> buildSessionOrder(List<Exercice> dueList, List<Exercice> newList) {
    final order = <Exercice>[];
    dueList.shuffle();
    newList.shuffle();
    final N = dueList.length;
    final M = newList.length;

    if (M == 0) {
      return List<Exercice>.from(dueList); // uniquement des révisions
    }
    if (N == 0) {
      return List<Exercice>.from(newList); // uniquement des nouveaux
    }

    final chunkSize = (N / M).floor();
    var indexDue = 0;
    var indexNew = 0;

    while (indexDue < N || indexNew < M) {
      // Ajouter un bloc de révisions
      for (var i = 0; i < chunkSize && indexDue < N; i++) {
        order.add(dueList[indexDue]);
        indexDue++;
      }

      // Ajouter un nouveau
      if (indexNew < M) {
        order.add(newList[indexNew]);
        indexNew++;
      }
    }
    return order;
  }
}