// ignore_for_file: unused_field, prefer_final_fields, unused_element

import '../exercises/answer/exercise_answer.dart';
import '../srs/srs_config.dart';
import '../srs/grade.dart';
import 'dart:math';
import 'srs_utils.dart';

/// Représente l'état SRS d'un exercice.
/// Gère les informations nécessaires pour l'algorithme SRS.
class SRSState {
  double _easeFactor;
  Duration _interval; // duration for review intervals
  Duration get interval => _interval;
  double _kFactor;
  double _w; //correspond à la mémoire long terme
  double _rbar; //moyenne pondéré des dernière victoire

  DateTime? _lastReview;
  DateTime? get nextReview => _lastReview?.add(_interval);

  List<RealExerciseAnswer> _history;

  int _learningStepIndex; // index in learning steps (-1 = not in learning)
  bool get isInLearning => _learningStepIndex >= 0;

  SRSState({
    double easeFactor = 2.5,
    Duration interval = const Duration(days: 1),
    double kFactor = 0.1,
    double w = 0.0,
    double rbar = 0.0,
    DateTime? lastReview,
    List<RealExerciseAnswer>? history,
    int learningStepIndex = 0,
  }) : _easeFactor = easeFactor,
       _interval = interval,
       _kFactor = kFactor,
       _w = w,
       _rbar = rbar,
       _lastReview = lastReview,
       _history = history ?? [],
       _learningStepIndex = learningStepIndex;

  SRSState.clone(SRSState other)
    : _easeFactor = other._easeFactor,
      _interval = other._interval,
      _kFactor = other._kFactor,
      _w = other._w,
      _rbar = other._rbar,
      _lastReview = other._lastReview,
      _history = List.of(other._history),
      _learningStepIndex = other._learningStepIndex;

  void copyFrom(SRSState other) {
    _easeFactor = other._easeFactor;
    _interval = other._interval;
    _kFactor = other._kFactor;
    _w = other._w;
    _rbar = other._rbar;
    _lastReview = other._lastReview;
    _history = other._history;
    _learningStepIndex = other._learningStepIndex;
  }

  /// Calcule et renvoie l'intervalle prévisionnel
  /// dans le cas où on est en mode review (learningStepIndex == -1)
  /// update les paramètre seulement si updateSelf == true
  Duration _reviewState(ExerciseAnswer answer, SRSConfig config, bool updateSelf) {
    assert(_learningStepIndex == -1);

    final DateTime now = answer.at;
    final q = answer.grade.toInt();
    final bool isSuccess = q >= 3;

    //l'idée est de modifié les champs de results,
    // puis à la fin seulement on utilise updateSelf et on modifie this si besoin.
    // Cela évite de créer une variable pour chaque champs
    final SRSState result = SRSState.clone(this);
    final double intervalDays = durationToDays(result._interval);

    // Step 1
    // Cas où il y a un retard sur l'intervalle prévu
    final double deltaDays = durationToDays(now.difference(result._lastReview ?? now));
    final double lateness = max(0.0, deltaDays - intervalDays);
    final double tolerance = min(config.longPause.toDouble(), config.minTolFactor * intervalDays);
    if (lateness >= tolerance && !isSuccess) {
      if (lateness >= config.longPause) {
        result._rbar = 0.0;
        result._w = 0.0;
      } else {
        result._rbar = result._rbar * exp(-config.mu * lateness);
        result._w = config.wMax * result._rbar;
      }
    }

    // Step 2
    // SM-2 alg
    final double arg = ((config.rstar - result._w) / (1.0 - result._w)).clamp(1e-9, 1.0 - 1e-9);
    final double logArg = log(arg);

    if (!isSuccess) {
      if (q == 0) {
        result._learningStepIndex = 0;
        result._interval = config.learningSteps.isNotEmpty
            ? config.learningSteps[0]
            : Duration(minutes: 1);
      } else {
        result._learningStepIndex = 1;
        result._interval = config.learningSteps.length > 1
            ? config.learningSteps[1]
            : Duration(minutes: 10);
      }
      result._kFactor = -logArg / max(1, durationToDays(result._interval));
    } else {
      result._learningStepIndex = -1;
      if (q == 3) {
        result._interval = daysToduration(max(1.0, intervalDays * config.hardReviewFactor));
        result._kFactor = -(logArg / durationToDays(result._interval));
      } else {
        result._kFactor = result._kFactor / result._easeFactor;
        result._interval = daysToduration(max(1, -(logArg / result._kFactor)));
      }
    }

    // apply multipliers
    if (q == 5) {
      result._interval = daysToduration(durationToDays(result._interval) * config.easyBonus);
    }
    result._interval = daysToduration(
      min(durationToDays(result._interval), config.iMax.toDouble()),
    );

    // EF update
    final double deltaEF = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02); // SM-2 formula
    result._easeFactor = max(result._easeFactor + deltaEF, config.efMin);

    // rbar and w update
    final double lambda = config.getLambda(q);
    result._rbar = (lambda * result._rbar) + ((1.0 - lambda) * (isSuccess ? 1.0 : 0.0));
    result._rbar = result._rbar.clamp(0.0, 1.0);
    result._w = config.wMax * result._rbar;

    result._lastReview = now;

    if (updateSelf) {
      copyFrom(result);
    }
    return result._interval;
  }

  /// Calcule et renvoie l'intervalle prévisionnel
  /// dans le cas où on est en mode learning (learningStepIndex >= 0)
  /// update les paramètre seulement si updateSelf == true
  Duration _learningState(ExerciseAnswer answer, SRSConfig config, bool updateSelf) {
    // _learningStepIndex >= config.config.learningSteps.length is OK (config can change)
    assert(_learningStepIndex >= 0);

    final DateTime now = answer.at;

    final SRSState result = SRSState.clone(this);
    final List<Duration> s = config.learningSteps;

    switch (answer.grade) {
      case Grade.again: // q=0
        result._interval = s.isNotEmpty ? s[0] : Duration(minutes: 1);
        result._learningStepIndex = 0;

      case Grade.hard: // q=2
        if (result._learningStepIndex > 0 && result._learningStepIndex < s.length) {
          result._interval = daysToduration(
            durationToDays(s[result._learningStepIndex]) * config.hardLearningFactor,
          );
        } else {
          result._interval = (s.length > 1)
              ? daysToduration(
                  (durationToDays(s[0]) + durationToDays(s[1])) * 0.5 * config.hardLearningFactor,
                )
              : Duration(minutes: 4);
        }

      case Grade.medium: // q=3
        if (result._learningStepIndex > 0 && result._learningStepIndex < s.length) {
          result._interval = s[result._learningStepIndex];
        } else {
          result._interval = (s.length > 1)
              ? daysToduration((durationToDays(s[0]) + durationToDays(s[1])) / 2.0)
              : Duration(minutes: 5, seconds: 30);
        }

      case Grade.good: // q=4
        final int nextIdx = result._learningStepIndex + 1;
        if (nextIdx < s.length - 1) {
          result._learningStepIndex = nextIdx;
          result._interval = s[nextIdx];
        } else {
          //cas de la dernière step du config (1 days par défaut)
          result._learningStepIndex = -1;
          final double arg = ((config.rstar - result._w) / (1.0 - result._w));
          final double logArg = log(arg.clamp(1e-9, 1.0 - 1e-9));

          result._interval = s[s.length - 1];
          result._kFactor = -logArg / durationToDays(result._interval);
        }

      case Grade.easy: // q=5
        result._learningStepIndex = -1;
        // set a provisional interval as easyInterval days -> review branch will use it next review
        final double arg = ((config.rstar - result._w) / (1.0 - result._w)).clamp(1e-9, 1.0 - 1e-9);
        final double logArg = log(arg);
        result._kFactor = -(logArg / config.easyInterval);
        result._interval = Duration(days: config.easyInterval);
        result._easeFactor = max(result._easeFactor + 0.1, config.efMin);
    }

    result._lastReview = now;

    if (updateSelf) {
      copyFrom(result);
    }
    return result._interval;
  }

  /// Met à jour l'état SRS en fonction de la note, de l'heure et de la configuration
  void applyAnswer(RealExerciseAnswer answer, SRSConfig config) {
    if (_learningStepIndex == -1) {
      // Note : on évite répétition du code en utilisant les meme fonction
      // pour updateState et pour getPreviewInterval
      _reviewState(answer, config, true);
    } else {
      _learningState(answer, config, true);
    }

    _history.add(answer);
    _checkInvariants(config);
  }

  /// renvoie l'intervalle prévisionnel pour une note donnée
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    final Duration? res;
    if (_learningStepIndex == -1) {
      res = _reviewState(answer, config, false);
    } else {
      res = _learningState(answer, config, false);
    }
    return res;
  }

  /// Vérifie les invariants de l'état SRS à la fin de chaque mise à jour
  void _checkInvariants(SRSConfig config) {
    const double eps = 1e-9;

    //invariants temporels
    //intervals
    if (!durationToDays(_interval).isFinite) {
      _interval = Duration(minutes: 1);
    } else if (durationToDays(_interval) <= eps) {
      _interval = Duration(minutes: 1);
    } else if (durationToDays(_interval) > durationToDays(Duration(days: config.iMax)) + eps) {
      _interval = Duration(days: config.iMax);
    }

    //invariants mathématiques
    //kFactor
    if (!_kFactor.isFinite) {
      // J'espère que ces cas n'arriveront jamais à un utilisateur
      // car ils se traduisent dans l'algorithme par une réinitialisation du coefficient d'oubli
      // et donc reset de l'inerval
      _kFactor = config.defaultKFactor;
    } else if (_kFactor <= eps) {
      _kFactor = config.defaultKFactor;
    }
    // rbar
    if (!_rbar.isFinite) {
      _rbar = 0.0;
    } else if (_rbar < 0.0) {
      _rbar = 0.0;
    } else if (_rbar > 1.0) {
      _rbar = 1.0;
    }
    // w
    if (!_w.isFinite) {
      _w = config.defaultW;
    } else if (_w < 0.0) {
      _w = 0.0;
    } else if (_w > config.wMax) {
      _w = config.wMax;
    }
    //ease factor
    if (!_easeFactor.isFinite) {
      _easeFactor = config.defaultEF;
    } else if (_easeFactor < config.efMin - eps) {
      _easeFactor = config.efMin;
    }

    //invariants d'état logique
    if (_learningStepIndex < -1) {
      _learningStepIndex = -1;
    } else if (_learningStepIndex >= config.learningSteps.length) {
      _learningStepIndex = config.learningSteps.length - 1;
    }
  }
}
