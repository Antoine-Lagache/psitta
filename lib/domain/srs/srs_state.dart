// ignore_for_file: unused_field, prefer_final_fields, unused_element

import '../srs/srs_config.dart';
import '../srs/grade.dart';
import 'dart:math';

/// Représente l'état SRS d'un exercice.
/// Gère les informations nécessaires pour l'algorithme SRS.
class SRSState {
  DateTime? _nextReview;
  double _easeFactor;
  Duration _interval; // duration for review intervals
  double _kFactor; //TODO: doit etre en 1/days ! Verrouiller ça et faire /!\
  double _w; //correspond à la mémoire long terme
  double _rbar; //moyenne pondéré des dernière victoire

  DateTime? _lastReview;
  List<dynamic> _history; //inutilisé pour l'instant

  int _learningStepIndex; // index in learning steps (-1 = not in learning)

  SRSState(
      {DateTime? nextReview,
      double easeFactor = 2.5,
      Duration interval = const Duration(days: 1),
      double kFactor = 0.1,
      double w = 0.0,
      double rbar = 0.0,
      DateTime? lastReview,
      List<dynamic>? history,
      int learningStepIndex = 0}):
      
       _nextReview = nextReview,
        _easeFactor = easeFactor,
        _interval = interval,
        _kFactor = kFactor,
        _w = w,
        _rbar = rbar,
        _lastReview = lastReview,
        _history = history ?? [],
        _learningStepIndex = learningStepIndex;

  // TOUTES les autres méthodes doivent etre privées

  /// Met à jour l'état SRS en fonction de la note, de l'heure et de la configuration
  void updateState(Grade grade, DateTime now, SRSConfig config) {
    // Implémentez la logique de mise à jour de l'état SRS en fonction de la note, de l'heure et de la configuration
    // TODO: implement SRS state update logic
  }

  /// renvoie l'intervalle prévisionnel pour une note donnée
  Duration? getPreviewInterval(Grade grade, DateTime now, SRSConfig config) {
    // TODO: implement logic to get preview interval
    return null;
  }

  /// Vérifie les invariants de l'état SRS à la fin de chaque mise à jour
bool _checkInvariants(SRSConfig config) {
  //TODO : Vérifié cette fonctions ainsi que tous les invariants
  const double eps = 1e-9;

  // --- helpers ---
  bool isFiniteNum(double x) => x.isFinite && !x.isNaN;
  double durationToDays(Duration d) =>
      d.inMilliseconds / Duration.millisecondsPerDay;

  // 1) Sanity des scalaires
  if (!isFiniteNum(_easeFactor) || _easeFactor < config.efMin - eps) return false;
  if (!isFiniteNum(_kFactor) || _kFactor <= 0.0 + eps) return false; // k > 0 (en 1/jour)
  if (!isFiniteNum(_rbar) || _rbar < 0.0 - eps || _rbar > 1.0 + eps) return false;

  // w doit rester borné et cohérent avec le modèle (w < rstar)
  if (!isFiniteNum(_w) || _w < 0.0 - eps) return false;
  if (_w > config.wMax + 1e-6) return false;      // w <= wMax
  if (_w >= config.rstar - 1e-6) return false;    // nécessaire pour que le log de la formule soit valide

  // 2) Intervalle valide
  if (_interval <= Duration.zero) return false;
  final double intervalDays = durationToDays(_interval);
  if (!intervalDays.isFinite || intervalDays <= 0.0) return false;
  if (intervalDays > config.iMax + 1e-6) return false;

  // 3) Cohérence learning index
  if (_learningStepIndex < -1) return false;
  if (_learningStepIndex >= 0 && _learningStepIndex >= config.learningSteps.length) {
    return false;
  }

  // 4) Cohérence temporelle (si dates disponibles)
  if (_lastReview != null && _nextReview != null) {
    if (!_nextReview!.isAfter(_lastReview!)) return false;
  }
  // Optionnel : on accepte nextReview null tant que non initialisé, mais si nextReview non null,
  // elle ne doit pas être dans le passé *par rapport à lastReview* (déjà couvert au-dessus).

  // 5) Invariant "cible de rétention" en mode review seulement
  // En learning, l'intervalle est souvent une step fixe, donc P(interval)=rstar n'a pas de sens.
  if (_learningStepIndex == -1) {
    final double p = (1.0 - _w) * exp(-_kFactor * intervalDays) + _w;
    if (!p.isFinite) return false;

    // On tolère un petit écart (clamp, arrondis, iMax, etc.)
    const double tol = 1e-3;
    if ((p - config.rstar).abs() > tol) return false;
  }

  return true;
}

}