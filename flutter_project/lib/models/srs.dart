// lib/models/srs.dart
import 'dart:math';

class SRSState {
  DateTime? nextReview;
  double easeFactor;
  Duration interval; // days for review intervals
  double kFactor;
  double w;
  double rbar;

  DateTime? lastReview;
  List<int> history;

  // NEW: index in learning steps (-1 = not in learning)
  int learningStepIndex;

  SRSState({
    this.nextReview,
    this.easeFactor = 2.5,
    this.interval =  const Duration(days: 1),
    this.kFactor = 0.1,
    this.w = 0.0,
    this.rbar = 0.0,
    this.lastReview,
    List<int>? history,
    this.learningStepIndex = 0,
  })  : history = history ?? [];

  // -----------------------------
  // PURE preview helpers (no mutation)
  // -----------------------------
  Duration computePreviewLearning(int q, SRSConfig config, {List<Duration>? steps}) {
    final List<Duration> s = steps ?? config.learningSteps;
    final int qq = q.clamp(0, 5);
    // learning semantics (mirror applyLearningAnswer but pure)
    if (qq == 0) return s.isNotEmpty ? s[0] : Duration(minutes: 1);
    if (qq == 2) {
      if(learningStepIndex > 0){
          return Duration(milliseconds: (s[learningStepIndex].inMilliseconds* config.hardLearningFactor).round());
        }else{
          return(s.length >1) ? Duration(milliseconds: ((s[0].inMilliseconds + s[1].inMilliseconds)*0.5*config.hardLearningFactor).round()) : Duration(minutes: 4);
        }
    }
    if (qq == 3) {
      // Medium -> Anki Hard equivalent
      if (learningStepIndex <= 0) {
        if (s.length > 1) {
          final int avgMs = ((s[0].inMilliseconds + s[1].inMilliseconds) / 2.0).round();
          return Duration(milliseconds: avgMs);
        } else {
          return Duration(minutes: 5, seconds: 30);
        }
      } else {
        return s[learningStepIndex];
      }
    }
    if (qq == 4) {
      final int nextIdx = learningStepIndex + 1;
      if (nextIdx < s.length){
        return s[nextIdx];
      }
      return Duration(milliseconds: (interval.inMilliseconds * easeFactor).round()); // will graduate to review with easyInterval
    }
    if (qq == 5) {
      return Duration(days: config.easyInterval); // immediate graduation
    }
    // fallback
    return s.isNotEmpty ? s[0] : Duration(minutes: 1);
  }

  Duration computePreviewReview(int q, SRSConfig config) {
    final int qq = q.clamp(0, 5);
    final bool isSuccess = qq >= 3;
    Duration simInterval;
    if (!isSuccess) {
      if(qq==0) {
        simInterval = config.learningSteps.isNotEmpty ? config.learningSteps[0] : Duration(minutes: 1);
      } else{
        simInterval = config.learningSteps.length > 1 ? config.learningSteps[1] : Duration(minutes: 10);
      }
    } else {
      if(qq==3){
        simInterval = Duration(milliseconds:max(24*3600*1000, (interval.inMilliseconds.toDouble() * config.hardReviewFactor).round()));
      }else {
        final double arg = ((config.rstar - w) / (1.0 - w)).clamp(1e-6, 1 - 1e-6);
        final double logArg = log(arg);
        final double kf = kFactor / easeFactor;
        final int computed = -(logArg / kf).round();
        simInterval = Duration(days: max(1, computed));
      }
    }
    if (qq == 5) simInterval = Duration(days: max(1, (interval.inDays * config.easyBonus).round()));
    simInterval = Duration(days : min(simInterval.inDays, config.iMax));
    return simInterval;
  }

  // -----------------------------
  // MUTATING functions: applyLearningAnswer / applyReviewAnswer
  // separated for clarity (you asked for split)
  // -----------------------------
  Duration applyLearningAnswer(int q, SRSConfig config, {List<Duration>? steps}) {
    final now = DateTime.now().toUtc();
    final List<Duration> s = steps ?? config.learningSteps;
    final int qq = q.clamp(0, 5);

    // AGAIN -> reset to first step
    if (qq == 0) {
      final Duration dur = s.isNotEmpty ? s[0] : Duration(minutes: 1);
      learningStepIndex = 0;
      nextReview = now.add(dur);
      history.add(qq);
      return dur;
    }
    // HARD
    if (qq == 2) {
      if(learningStepIndex > 0 && learningStepIndex < s.length){
          final Duration dur = Duration(milliseconds: (s[learningStepIndex].inMilliseconds* config.hardLearningFactor).round());
          nextReview = now.add(dur);
          history.add(qq);
          return dur;
        }else{
          final Duration dur = (s.length >1)
            ? Duration(milliseconds: ((s[0].inMilliseconds + s[1].inMilliseconds)*0.5*config.hardLearningFactor).round())
            : Duration(minutes: 4);
          nextReview = now.add(dur);
          history.add(qq);
          return dur;
        }
    }

    // MEDIUM (Anki Hard equivalent)
    if (qq == 3) {
      if (learningStepIndex <= 0) {
        if (s.length > 1) {
          final int avgMs = ((s[0].inMilliseconds + s[1].inMilliseconds) / 2.0).round();
          final Duration dur = Duration(milliseconds: avgMs);
          nextReview = now.add(dur);
          history.add(qq);
          return dur;
        } else {
          final Duration dur = Duration(minutes: 5, seconds: 30);
          nextReview = now.add(dur);
          history.add(qq);
          return dur;
        }
      } else if (learningStepIndex < s.length){
        final Duration dur = s[learningStepIndex];
        nextReview = now.add(dur);
        history.add(qq);
        return dur;
      } else {
        // fallback si index invalide
        final Duration dur = Duration(minutes: 10);
        nextReview = now.add(dur);
        history.add(qq);
        return dur;
  }
    }

    // GOOD -> advance step or graduate
    if (qq == 4) {
      final int nextIdx = learningStepIndex + 1;
      if (nextIdx < s.length) {
        learningStepIndex = nextIdx;
        final Duration dur = s[nextIdx];
        nextReview = now.add(dur);
        history.add(qq);
        return dur;
      } else {
        // graduate to review: set interval to 0 days first (will be computed by review logic)
        learningStepIndex = -1;
        final double arg = ((config.rstar - w) / (1.0 - w)).clamp(1e-6, 1.0 - 1e-6);
        final double logArg = log(arg);
        kFactor = -(logArg*24*3600*1000/interval.inMilliseconds);
        // fall through to review behavior below by calling applyReviewAnswer
      }
    }

    // EASY -> immediate graduation with easyInterval
    if (qq == 5) {
      learningStepIndex = -1;
      // set a provisional interval as easyInterval days -> review branch will use it
      final double arg = ((config.rstar - w) / (1.0 - w)).clamp(1e-6, 1.0 - 1e-6);
      final double logArg = log(arg);
      kFactor = -(logArg/config.easyInterval);
      interval = Duration(days: config.easyInterval);
      easeFactor = max(easeFactor + 0.1, config.efMin);
      final double lam = config.getLambda(qq);
      rbar = (lam * rbar) + ((1.0 - lam));
      rbar = rbar.clamp(0.0, 1.0);
      w = config.wMax * rbar;
      return interval;
      // fall through to review
    }

    // If we reached here and learningStepIndex == -1 -> treat as graduation => call review apply
    return applyReviewAnswer(q, config);
  }

  Duration applyReviewAnswer(int q, SRSConfig config) {
    final now = DateTime.now().toUtc();
    final int qq = q.clamp(0, 5);
    final bool isSuccess = qq >= 3;

    // deltaDays used for long pause handling
    final double deltaDays = lastReview == null ? 0.0 : now.difference(lastReview!).inDays.toDouble();
    final double l = max(0.0, deltaDays - interval.inDays.toDouble());
    final double tol = min(config.longPause.toDouble(), config.minTolFactor * interval.inDays.toDouble());
    if (l >= tol && !isSuccess) {
      if (l >= config.longPause) {
        rbar = 0.0;
        w = 0.0;
      } else {
        rbar = rbar * exp(-config.mu * l);
        w = config.wMax * rbar;
      }
    }

    final double arg = ((config.rstar - w) / (1.0 - w)).clamp(1e-6, 1.0 - 1e-6);
    final double logArg = log(arg);

    if (!isSuccess) {
      if(qq==0) {
        learningStepIndex = 0;
        interval = config.learningSteps.isNotEmpty ? config.learningSteps[0] : Duration(minutes: 1);
      } else{
        learningStepIndex = 1;
        interval = config.learningSteps.length > 1 ? config.learningSteps[1] : Duration(minutes: 10);
      }
      kFactor = -logArg / max(1, interval.inDays);
    } else {
      if(qq == 3){
        interval = Duration(milliseconds:max(24*3600*1000, (interval.inMilliseconds.toDouble() * config.hardReviewFactor).round()));
        kFactor = -(logArg*24*3600*1000/ interval.inMilliseconds);
      }else{
        kFactor = kFactor / easeFactor;
        final double computed = -(logArg / kFactor);
        interval = Duration(days: max(1, computed.round()));
      }
    }

    // apply multipliers
    if (qq == 5) interval = Duration(days: max(1, (interval.inDays * config.easyBonus).round()));
    interval = Duration(days : min(interval.inDays, config.iMax));

    // EF update only in review
    final double deltaEF = 0.1 - (5 - qq) * (0.08 + (5 - qq) * 0.02);
    easeFactor = max(easeFactor + deltaEF, config.efMin);

    final double lam = config.getLambda(qq);
    final double obs = isSuccess ? 1.0 : 0.0;
    rbar = (lam * rbar) + ((1.0 - lam) * obs);
    rbar = rbar.clamp(0.0, 1.0);
    w = config.wMax * rbar;


    lastReview = now;
    nextReview = now.add(interval);
    history.add(qq);
    return interval;
  }
}

class SRSConfig {
  final double rstar;
  final double wMaxFactor;
  final List<double> lambdas;
  final int easyInterval; // days
  final int firstIntervalFallback; // used for SM-2 first review
  final double efMin;
  final int iMax;
  final double defaultEF;
  final double defaultW;

  final double mu;
  final int longPause;
  final double minTolFactor;

  final List<Duration> learningSteps;
  final double hardReviewFactor;
  final double hardLearningFactor;
  final double easyBonus;
  final Duration dayBoundary; // 0..23, Anki-like day boundary

  static const List<double> _defaultLambdas = [0.60, 0.90, 0.80, 0.95, 0.85, 0.70];

  SRSConfig({
    this.rstar = 0.9,
    this.wMaxFactor = 0.95,
    List<double>? lambdas,
    this.easyInterval = 4,
    this.firstIntervalFallback = 1,
    this.efMin = 1.3,
    this.iMax = 5 * 365,
    this.defaultEF = 2.5,
    this.defaultW = 0.0,
    this.mu = 0.03,
    this.longPause = 60,
    this.minTolFactor = 0.2,
    this.learningSteps = const [
      Duration(minutes: 1),
      Duration(minutes: 10),
      Duration(days: 1),
    ],
    this.hardReviewFactor = 1.2,
    this.hardLearningFactor = 0.7,
    this.easyBonus = 1.3,
    this.dayBoundary = Duration.zero,
  })  : lambdas = List.generate(
          6,
          (i) {
            if (lambdas != null && i < lambdas.length) return lambdas[i].clamp(0.0, 1.0);
            return _defaultLambdas[i];
          },
        ),
        assert(rstar > 0 && rstar < 1),
        assert(wMaxFactor > 0 && wMaxFactor < 1);

  double get wMax => wMaxFactor * rstar;

  double getLambda(int q) {
    final int idx = q.clamp(0, lambdas.length - 1);
    return lambdas[idx];
  }
}
