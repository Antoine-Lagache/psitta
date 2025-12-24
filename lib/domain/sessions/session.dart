import '../exercices/exercice.dart';
import '../srs/srs_config.dart';
import 'session_result.dart';
import '../srs/grade.dart';

/// Types de sessions possibles
enum SessionType {
  wordSession,
  sentenceSession,
}

/// Classe représentant une session d'exercices avec SRS.
/// Les méthodes sont implémentées par les classes concrètes (WordSession, SentenceSession, etc.)
class Session {
  /// Date et heure de début de la session
  /// null si la session n'a pas encore commencé
  DateTime? _startedAt;
  DateTime? get startedAt => _startedAt;

  /// Configuration SRS utilisée pour cette session
  final SRSConfig config;

  /// Résultat intermediaire de la session
  /// modifié à chaque soumission de réponse
  /// renvoyé par endSession ou endSessionEarly
  SessionResult? _intermediateResult;
  SessionResult? get intermediateResult => _intermediateResult;

  /// Liste des exercices dans la session
  /// triée dynamiquement selon l'état des exercices
  final List<Exercice> _exercices;
  List<Exercice> get exercices => List.unmodifiable(_exercices);

  /// Exercice courant dans la session
  /// null si aucun exercice en cours
  /// fait partie de la liste exercices
  Exercice? _current;


  Session(this._exercices, SessionType sessionType, {required this.config})  {
    _initSession(sessionType);
  }

  /// Initialise la session en initialisant les exercices.
  /// modifie l'ordre des exercices en fonction de leur état, et fait quelques vérifications.
  void _initSession(SessionType sessionType){
    // TODO
  }

  /// Démarre la session à la date et heure donnée.
  /// ne fait rien si la session a déjà commencé
  void beginSession(DateTime now){
    _startedAt ??= now;
    _nextExercice();
  }

  /// renvoie le nombre d'exercices à faire ou à refaire dans la session
  int numberOfRemainingExercices(){
    // TODO
    return 0;
  }

  /// passe à l'exercice suivant dans la session
  /// ne fait rien s'il n'y a pas d'exercice suivant
  void _nextExercice(){
    // TODO
  }

  /// renvoie l'exercice courant, ou null s'il n'y en a pas
  Exercice? getCurrentExercice(){
    return _current;
  }

  /// soumet la réponse pour l'exercice courant avec la note donnée, puis passe à l'exercice suivant
  /// renvoie l'exercice mis à jour après application de la SRS
  /// renvoie null s'il n'y a pas d'exercice courant ou si la session n'a pas commencé
  Exercice? submitAnswer(Grade grade, DateTime now){
    // TODO
    _nextExercice();
    return null;
  }

  /// renvoie l'intervalle prévisionnel pour l'exercice courant et une note donnée
  /// renvoie null s'il n'y a pas d'exercice courant ou si la session n'a pas commencé
  Duration? getPreviewInterval(Grade grade, DateTime now){
    // TODO
    return null;
  }

  /// termine la session de manière anticipée et renvoie le résultat partiel
  /// une session terminée ne peut plus recevoir de réponses et doit etre supprimée
  SessionResult? endSessionEarly(DateTime now){
    // TODO
    // need to use this._intermediateResult to make sure that submit answer is not called after this.
    // cannot return null ??
    return null;
  }

  /// termine la session normalement et renvoie le résultat
  /// renvoie null si la session n'est pas terminée
  /// une session terminée ne peut plus recevoir de réponses et doit etre supprimée
  SessionResult? endSession(DateTime now){
    // TODO
    // need to use this._intermediateResult to make sure that submit answer is not called after this.
    // cannot return null ??
    return null;
  }
}