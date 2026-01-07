import '../exercices/exercice.dart';
import '../srs/srs_config.dart';
import 'session_result.dart';
import '../srs/grade.dart';
import 'session_type.dart';


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
  /// /// SessionType n'est utilisé que lors de l'initialisation et ne doit pas etre stocké
  void _initSession(SessionType sessionType){
    // TODO
  }

  /// Démarre la session à la date et heure donnée.
  /// ne fait rien si la session a déjà commencé
  void beginSession(DateTime now){
    assert(_startedAt == null);
    _startedAt ??= now;
    _nextExercice();
  }

  /// renvoie le nombre d'exercices à faire ou à refaire dans la session
  int numberOfRemainingExercices(){
    // TODO
    return 0;
  }

  /// Réordonne la liste des exercices existants sans en ajouter ni en retirer.
  /// Utilise l'état des exercices et leur SRSState pour déterminer la priorité.
  void updateExerciceOrder(){
    // TODO
  }

  /// passe à l'exercice suivant dans la session
  /// ne fait rien s'il n'y a pas d'exercice suivant
  void _nextExercice(){
    updateExerciceOrder();
    // TODO
  }

  SessionResult getSessionResult(){
    assert(_intermediateResult != null);
    return _intermediateResult!;
  }

  /// renvoie l'exercice courant, lève une exception s'il n'y en a pas
  Exercice getCurrentExercice(){
    assert(_current != null);
    return _current!;
  }

  /// soumet la réponse pour l'exercice courant avec la note donnée, puis passe à l'exercice suivant
  /// renvoie l'exercice mis à jour après application de la SRS
  ///  Lève une exception s'il n'y a pas d'exercice courant ou si la session n'a pas commencé
  Exercice submitAnswer(Grade grade, DateTime now){
    // TODO
    _nextExercice();
    throw UnimplementedError("TODO");
  } 

  /// renvoie l'intervalle prévisionnel pour l'exercice courant et une note donnée
  ///  Lève une exception s'il n'y a pas d'exercice courant ou si la session n'a pas commencé
  Duration getPreviewInterval(Grade grade, DateTime now){
    // TODO
    return Duration();
  }

  /// termine la session de manière anticipée et renvoie le résultat partiel
  /// une session terminée ne peut plus recevoir de réponses et doit etre supprimée
  /// Lève une exception en cas de problème (session non commencé ou déja terminé)
  SessionResult endSessionEarly(DateTime now){
    // TODO
    // need to use this._intermediateResult.endAt to make sure that submit answer is not called after this.
    throw UnimplementedError("TODO");
  }

  /// termine la session normalement et renvoie le résultat
  /// renvoie null ssi il reste des exercices à faire dans la session
  /// une session terminée ne peut plus recevoir de réponses et doit etre supprimée
  /// Lève une exception en cas de problème (session non commencé ou déja terminé)
  SessionResult endSession(DateTime now){
    // TODO
    // need to use this._intermediateResult.endAt to make sure that submit answer is not called after this.
    throw UnimplementedError("TODO");
  }
}