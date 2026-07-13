import 'package:psitta/domain/exercises/answer/exercise_answer.dart';
import 'package:psitta/domain/exercises/exercise_status.dart';
import 'package:psitta/domain/prompt/exercice_prompt.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/domain/srs/srs_state.dart';

export 'package:psitta/domain/exercises/answer/exercise_answer.dart';
export 'package:psitta/domain/exercises/exercise_status.dart';
export 'package:psitta/domain/prompt/exercice_prompt.dart';
export 'package:psitta/domain/srs/srs_config.dart';
export 'package:psitta/domain/srs/srs_state.dart';

/// Classe abstraite représentant un exercice générique.
/// gère l'algo intra-session et l'état SRS de l'exercice.
abstract class Exercise {
  ExerciseStatus status;

  SRSState srsState;

  Exercise(this.status, this.srsState);

  /// renvoie le prompt de l'exercice (pour l'UI)
  ExercicePrompt getPrompt();

  /// Soumet la réponse de l'utilisateur avec une note Grade et met à jour l'état SRS
  void applyAnswer(RealExerciseAnswer answer, SRSConfig config) {
    assert(status != ExerciseStatus.completed);
    srsState.applyAnswer(answer, config);

    final DateTime nextDay = DateTime(
      answer.at.year,
      answer.at.month,
      answer.at.day,
    ).add(config.dayBoundary).toUtc();

    if (answer.at.toUtc().add(srsState.interval).isAfter(nextDay) && !srsState.isInLearning) {
      status = ExerciseStatus.completed;
    } else {
      if (status == ExerciseStatus.newExercise) {
        status = ExerciseStatus.learning;
      } else if (status == ExerciseStatus.toreview) {
        status = ExerciseStatus.relearning;
      }
    }
  }

  /// renvoie l'intervalle prévisionnel pour une note donnée
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    return srsState.previewInterval(answer, config);
  }

  /// Vérifie si une note Grade est autorisée pour cet exercice
  bool isGradeAllowed(Grade grade) {
    // Par défaut, toutes les notes sont autorisées
    return true;
  }
}
