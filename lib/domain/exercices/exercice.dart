import '../srs/srs_config.dart';
import '../srs/srs_state.dart';
import '../prompt/exercice_prompt.dart';
import 'exercice_status.dart';
import '../srs/grade.dart';


abstract class Exercice {
  ExerciceStatus status;

  SRSState srsState;

  Exercice(this.status, this.srsState);

  /// renvoie le prompt de l'exercice (pour l'UI)
  ExercicePrompt getPrompt();

  /// Soumet la réponse de l'utilisateur avec une note Grade et met à jour l'état SRS
  void submitAnswer(Grade grade, DateTime now, SRSConfig config) {
    srsState.updateState(grade, now, config);
    //TODO: update status based on grade
  }

  /// Vérifie si une note Grade est autorisée pour cet exercice
  bool isGradeAllowed(Grade grade) {
    // Par défaut, toutes les notes sont autorisées
    return true;
  }

}