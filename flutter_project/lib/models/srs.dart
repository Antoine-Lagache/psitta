
import 'dart:math';

class SRSState {
  DateTime? nextReview;

  int repetitionCount;
  double easeFactor;
  double interval;
  double kFactor;
  double w;
  double rbar;

  DateTime? lastReview;
  List<int>? history;

  SRSState({
    DateTime? nextReview,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.kFactor = 0.1,
    this.w = 0.0,
    this.rbar = 0.0,

    DateTime? lastReview,
    List<int>? history,
  }): history = history ?? [];

  void update(int q, SRSConfig config){
    final bool isSuccess = q >= 3;

    //on calcule le temps depuis la dernière révision
    final now = DateTime.now();
    // --- delta en jours (sécurisé) ---
    final double deltaDays = lastReview == null
        ? 0.0
        : now.difference(lastReview!).inDays.toDouble();

    // --- tolérance pour reset long terme ---
    // Assure-toi que config.longPause et config.minTolFactor sont en jours / sans unité mixte.
    final double l = max(0.0, deltaDays - interval); // retard effectif en jours
    final double tol = min(config.longPause, config.minTolFactor * interval);

    if(l >= tol && !isSuccess){
      if(l >= config.longPause){ //long terme se reset si long pause
        rbar = 0;
        w = 0;
      }else{ // petite pause, long terme baisse sans reset
        rbar = rbar* exp(-config.mu * l);
        w = config.wMax * rbar;
      }
    }

    // --- 1. Préparer les constantes ---
    // On calcule l'argument du log pour la loi exponentielle.
    final double arg = ((config.rstar - w) / (1.0 - w)).clamp(1e-6, 1.0-1e-6);
    final double logArg = log(arg);

    if (!isSuccess) {
      // --- 2. Cas échec ---
      repetitionCount = 0;
      interval = config.firstInterval;
      kFactor = -logArg / interval;
    } else {
      // --- 3. Cas succès ---
      if (repetitionCount == 0) {
        // première réussite
        interval = config.secondInterval;
        repetitionCount = 1;
        kFactor = -logArg / interval;
      } else {
        // répétition >= 2
        kFactor = kFactor / easeFactor;
        interval = -logArg / kFactor;
        repetitionCount += 1;
      }
    }

    // --- 4. Mise à jour de l’Ease Factor ---
    // Formule SM-2 : ΔEF = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)
    final deltaEF = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    easeFactor = max((easeFactor + deltaEF), config.efMin);

    // --- 5. Mise à jour de Rbar et w ---
    rbar = config.lambda * rbar + (1 - config.lambda) * (isSuccess ? 1.0 : 0.0);
    rbar = rbar.clamp(0.0, 1.0);
    w = config.wMax * rbar;

    // --- 6. Mise à jour du planning ---
    lastReview = now;
    nextReview = now.add(Duration(hours: (interval * 24).round(),));

    // --- 7. Historique ---
    history = history ?? [];
    history!.add(q); //je ne comprend pas les ?. est ce ca marche si c'est null ???
  }
}

class SRSConfig {
  final double rstar;
  final double wMaxFactor;
  final double lambda;
  final double firstInterval;
  final double secondInterval;
  final double efMin;
  final int iMax;
  final double defaultEF;
  final double defaultW;

  final double mu;
  final double longPause;
  final double minTolFactor;

  SRSConfig({
    this.rstar = 0.9,
    this.wMaxFactor  = 0.95,
    this.lambda  = 0.9,
    this.firstInterval  = 1,
    this.secondInterval  = 6,
    this.efMin = 1.3,
    this.iMax = 5*365,
    this.defaultEF = 2.5,
    this.defaultW = 0.0,
    this.mu = 0.03,
    this.longPause = 60,
    this.minTolFactor = 0.2
  }) : assert(rstar > 0 && rstar < 1,
            'rstar doit être strictement entre 0 et 1'),
        assert(wMaxFactor > 0 && wMaxFactor < 1,
            'wMaxFactor doit être strictement entre 0 et 1'),
        assert(lambda > 0 && lambda < 1,
            'lambda doit être strictement entre 0 et 1');

  double get wMax => wMaxFactor * rstar;
}