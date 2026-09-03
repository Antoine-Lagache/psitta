import 'dart:math';

import 'package:psitta/domain/answer/exercise_answer.dart';
import 'package:psitta/domain/srs/srs_config.dart';
import 'package:psitta/utils/conversion/time_conversion.dart';

/// Holds and evolves the scheduling parameters for one exercise.
///
/// The mathematical meaning of each parameter is documented with the SRS
/// algorithm; this class owns the transitions between learning and review.
class SRSState {
  double _easeFactor;
  double get easeFactor => _easeFactor;

  Duration _interval;
  Duration get interval => _interval;

  double _kFactor;
  double get kFactor => _kFactor;

  double _w;
  double get w => _w;

  double _rbar;
  double get rbar => _rbar;

  DateTime? _lastReview;
  DateTime? get lastReview => _lastReview;

  DateTime? get nextReview => _lastReview?.add(_interval);

  /// Index in the configured learning steps; `-1` means review mode.
  int _learningStepIndex;
  int get learningStepIndex => _learningStepIndex;
  bool get isInLearning => _learningStepIndex >= 0;

  SRSState({
    double easeFactor = 2.5,
    Duration interval = const Duration(days: 1),
    double kFactor = 0.1,
    double w = 0.0,
    double rbar = 0.0,
    DateTime? lastReview,
    int learningStepIndex = 0,
  }) : _easeFactor = easeFactor,
       _interval = interval,
       _kFactor = kFactor,
       _w = w,
       _rbar = rbar,
       _lastReview = lastReview,
       _learningStepIndex = learningStepIndex;

  SRSState.clone(SRSState other)
    : _easeFactor = other._easeFactor,
      _interval = other._interval,
      _kFactor = other._kFactor,
      _w = other._w,
      _rbar = other._rbar,
      _lastReview = other._lastReview,
      _learningStepIndex = other._learningStepIndex;

  void copyFrom(SRSState other) {
    _easeFactor = other._easeFactor;
    _interval = other._interval;
    _kFactor = other._kFactor;
    _w = other._w;
    _rbar = other._rbar;
    _lastReview = other._lastReview;
    _learningStepIndex = other._learningStepIndex;
  }

  Duration _reviewState(ExerciseAnswer answer, SRSConfig config, bool updateSelf) {
    assert(_learningStepIndex == -1);

    final DateTime now = answer.at;
    final q = answer.grade.toInt();
    final bool isSuccess = q >= 3;

    // Calculate against a copy so previews and real updates share one formula.
    final SRSState result = SRSState.clone(this);
    final double intervalDays = durationToDays(result._interval);

    // Apply the model's late-review correction.
    final double deltaDays = durationToDays(now.difference(result._lastReview ?? now));
    final double lateness = max(0.0, deltaDays - intervalDays);
    final double tolerance = min(
      config.longPause.toDouble(),
      config.minTolFactor * intervalDays,
    );
    if (lateness >= tolerance && !isSuccess) {
      if (lateness >= config.longPause) {
        result._rbar = 0.0;
        result._w = 0.0;
      } else {
        result._rbar = result._rbar * exp(-config.mu * lateness);
        result._w = config.wMax * result._rbar;
      }
    }

    // Apply the SM-2-derived interval calculation.
    final double arg = ((config.rstar - result._w) / (1.0 - result._w)).clamp(
      1e-9,
      1.0 - 1e-9,
    );
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
        result._interval = daysToduration(
          max(1.0, intervalDays * config.hardReviewFactor),
        );
        result._kFactor = -(logArg / durationToDays(result._interval));
      } else {
        result._kFactor = result._kFactor / result._easeFactor;
        result._interval = daysToduration(max(1, -(logArg / result._kFactor)));
      }
    }

    // Apply grade-specific interval multipliers.
    if (q == 5) {
      result._interval = daysToduration(
        durationToDays(result._interval) * config.easyBonus,
      );
    }
    result._interval = daysToduration(
      min(durationToDays(result._interval), config.iMax.toDouble()),
    );

    // Update the ease factor.
    final double deltaEF = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02); // SM-2 formula
    result._easeFactor = max(result._easeFactor + deltaEF, config.efMin);

    // Update recall and weight estimates.
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

  Duration _learningState(ExerciseAnswer answer, SRSConfig config, bool updateSelf) {
    // A changed configuration may temporarily leave the index past its steps.
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
                  (durationToDays(s[0]) + durationToDays(s[1])) *
                      0.5 *
                      config.hardLearningFactor,
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
          // Completing the final learning step switches the state to review mode.
          result._learningStepIndex = -1;
          final double arg = ((config.rstar - result._w) / (1.0 - result._w));
          final double logArg = log(arg.clamp(1e-9, 1.0 - 1e-9));
          // Reuse the default final step when no explicit learning step exists.
          final graduationInterval = s.isNotEmpty ? s.last : const Duration(days: 1);

          result._interval = graduationInterval;
          result._kFactor = -logArg / durationToDays(result._interval);
        }

      case Grade.easy: // q=5
        result._learningStepIndex = -1;
        // Easy exits learning directly with the configured review interval.
        final double arg = ((config.rstar - result._w) / (1.0 - result._w)).clamp(
          1e-9,
          1.0 - 1e-9,
        );
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

  /// Applies [answer] and mutates the scheduling state.
  void applyAnswer(SubmittedExerciseAnswer answer, SRSConfig config) {
    if (_learningStepIndex == -1) {
      // The update and preview paths intentionally share the same calculation.
      _reviewState(answer, config, true);
    } else {
      _learningState(answer, config, true);
    }

    _checkInvariants(config);
  }

  /// Returns the expected interval without modifying this state.
  Duration previewInterval(PreviewExerciseAnswer answer, SRSConfig config) {
    final Duration? res;
    if (_learningStepIndex == -1) {
      res = _reviewState(answer, config, false);
    } else {
      res = _learningState(answer, config, false);
    }
    return res;
  }

  /// Repairs numeric and logical state that falls outside configured bounds.
  void _checkInvariants(SRSConfig config) {
    const double eps = 1e-9;

    // Temporal interval bounds.
    if (!durationToDays(_interval).isFinite) {
      _interval = Duration(minutes: 1);
    } else if (durationToDays(_interval) <= eps) {
      _interval = Duration(minutes: 1);
    } else if (durationToDays(_interval) >
        durationToDays(Duration(days: config.iMax)) + eps) {
      _interval = Duration(days: config.iMax);
    }

    // Mathematical bounds: k-factor.
    if (!_kFactor.isFinite) {
      _kFactor = config.defaultKFactor;
    } else if (_kFactor <= eps) {
      _kFactor = config.defaultKFactor;
    }
    // Recall estimate.
    if (!_rbar.isFinite) {
      _rbar = 0.0;
    } else if (_rbar < 0.0) {
      _rbar = 0.0;
    } else if (_rbar > 1.0) {
      _rbar = 1.0;
    }
    // Weight estimate.
    if (!_w.isFinite) {
      _w = config.defaultW;
    } else if (_w < 0.0) {
      _w = 0.0;
    } else if (_w > config.wMax) {
      _w = config.wMax;
    }
    // Ease factor.
    if (!_easeFactor.isFinite) {
      _easeFactor = config.defaultEF;
    } else if (_easeFactor < config.efMin - eps) {
      _easeFactor = config.efMin;
    }

    // Logical bounds: learning-step index.
    if (_learningStepIndex < -1) {
      _learningStepIndex = -1;
    } else if (_learningStepIndex >= config.learningSteps.length) {
      _learningStepIndex = config.learningSteps.length - 1;
    }
  }
}
