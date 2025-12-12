import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/exercice.dart';
import '../models/srs.dart';
import '../services/database_service.dart';
import '../services/screens_utils.dart';

enum _FinishAction { retry, quitAnyway }

/// The main screen for a learning session.
/// Displays flashcards and handles user answers.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late Session session;
  WordExercice? currentExercice;
  bool isLoading = true;
  bool showBack = false;
  int answeredCount = 0;
  String? errorMessage;

  /// Liste tampon pour les sauvegardes échouées
  final List<WordExercice> _pendingUpdates = [];

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  /// Charge la session depuis la base de données.
  Future<void> _initializeSession() async {
    try {
      final db = DatabaseService.instance;
      final configs = await db.getAllSrsConfigs();
      final SRSConfig config = configs.isEmpty ? SRSConfig() : configs.first;

      final dueList = await db.getDueExercices();
      final newList = await db.getNewExercices(config.newCount);

      session = Session(newList, dueList, config);
      currentExercice = session.chooseExercice() as WordExercice?;
    } catch (e, s){
      debugPrint('*ERREUR* lors du chargement de la session: $e\n$s');
      errorMessage = e.toString();
      currentExercice = null;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          showBack = false;
          answeredCount = 0;
        });
      }
    }
  }

  /// Sauvegarde un exercice dans la base, ou le met dans le buffer si erreur.
  Future<void> _saveExercise(WordExercice exo) async {
    try {
      final db = DatabaseService.instance;
      await db.updateWordExercice(exo);
    } catch (e) {
      debugPrint('/!\\ Sauvegarde échouée : $e');
      if (!_pendingUpdates.contains(exo)) {
        _pendingUpdates.add(exo);
      }
    }
  }

  /// Retente les sauvegardes échouées.
  /// Supprime du buffer les exercices qui passent, laisse les autres.
  Future<void> _flushPending() async {
    if (_pendingUpdates.isEmpty) return;
    debugPrint('Tentative de flush (${_pendingUpdates.length})...');
    final db = DatabaseService.instance;
    for (final e in List<WordExercice>.from(_pendingUpdates)) {
      try {
        await db.updateWordExercice(e);
        _pendingUpdates.remove(e);
      } catch (err) {
        debugPrint('Flush échoué pour ${e.id} : $err');
        // On ne break pas ; on continue d'essayer les autres.
        // On ne supprime pas l'exo en échec pour le retenter plus tard.
      }
    }
  }

  /// Affiche le verso de la carte.
  void _showAnswer() {
    if (mounted) setState(() => showBack = true);
  }

  /// Enregistre la réponse utilisateur.
  Future<void> _onAnswerSelected(int grade) async {
    if (currentExercice == null) return;

    try {
      session.submitAnswer(currentExercice!, grade);
      await _saveExercise(currentExercice!);
      await _flushPending(); // essaye aussi les sauvegardes ratées précédentes

      if (!session.hasNext()) {
        await _finishSession(true);
        return;
      }

      if (!mounted) return;
      setState(() {
        currentExercice = session.chooseExercice() as WordExercice?;
        showBack = false;
        answeredCount++;
      });
    } catch (e, s) {
      debugPrint('*ERREUR* pendant la réponse: $e\n$s');
      if (mounted) {
        setState(() => errorMessage = e.toString());
      }
    }
  }


  /// Affiche les intervalles prévus pour chaque niveau de réponse.
  Map<int, String> _predictNextIntervals(Exercice exo) {
    const grades = [0, 2, 3, 4, 5];
    return {
      for (final q in grades) q: formatDuration(session.getPreviewInterval(exo, q))
    };
  }

  /// Méthode unique pour terminer la session (utilisée pour "Quit" et "Completed").
  /// isDone == true  -> fin normale (done:true)
  /// isDone == false -> quitté par l'utilisateur (done:false)
  Future<void> _finishSession(bool isDone) async {
    if (!mounted) return;

    setState(() {
      isLoading = true; // marque qu'on fait une opération finale
    });

    try {
      // On tente d'abord un flush simple
      await _flushPending();

      // Tant que des éléments restent en attente, on propose à l'utilisateur de réessayer ou quitter.
      while (_pendingUpdates.isNotEmpty) {
        if (!mounted) return;

        final action = await showDialog<_FinishAction>(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            title: const Text('Erreur de sauvegarde'),
            content: Text(
              'Certaines cartes (${_pendingUpdates.length}) n’ont pas pu être enregistrées. '
              'Souhaitez-vous réessayer maintenant ou quitter quand même ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, _FinishAction.retry),
                child: const Text('Réessayer'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _FinishAction.quitAnyway),
                child: const Text('Quitter quand même'),
              ),
            ],
          ),
        );

        if (action == _FinishAction.retry) {
          // tenter à nouveau
          await _flushPending();
          // si tout est vide, la boucle s'arrêtera naturellement
          continue;
        } else if (action == _FinishAction.quitAnyway || action == null) {
          // utilisateur choisit de quitter malgré tout (ou ferme le dialog)
          break;
        }
      }

      // On arrive ici soit tout a été flushé, soit l'utilisateur a choisi de quitter quand même.
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, {'done': isDone, 'answered': answeredCount});
      } else {
        // écran racine : afficher un résumé
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Session terminée'),
            content: Text(isDone
                ? 'Vous avez répondu à $answeredCount cartes.'
                : 'Session quittée. $answeredCount cartes répondues.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e, s) {
      debugPrint('Erreur lors de la finalisation de session : $e\n$s');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erreur'),
          content: Text('Une erreur est survenue lors de la finalisation : $e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Affiche la carte (recto/verso)
  Widget _buildCardView() {
    final note = currentExercice!.card.note;
    final front = note.data['front'] ?? 'front';
    final back = note.data['back'] ?? 'back';

    if (!showBack) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(front, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAnswer,
            child: const Text("Retourner la carte"),
          ),
        ],
      );
    } else {
      final predictions = _predictNextIntervals(currentExercice!);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(back, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 20),
          for (final entry in predictions.entries)
            ElevatedButton(
              onPressed: () => _onAnswerSelected(entry.key),
              child: Text('${_gradeLabel(entry.key)}: ${entry.value}'),
            ),
        ],
      );
    }
  }

  String _gradeLabel(int grade) {
    switch (grade) {
      case 0:
        return 'Again';
      case 2:
        return 'Hard';
      case 3:
        return 'Medium';
      case 4:
        return 'Good';
      case 5:
        return 'Easy';
      default:
        return 'Grade $grade';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chargement
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Erreur
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Une erreur est survenue :'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    errorMessage = null;
                    isLoading = true;
                  });
                  _initializeSession();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Aucune carte
    if (currentExercice == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session'),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _finishSession(false),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Aucune carte à réviser pour l’instant.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _finishSession(true),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    }

    // Session normale
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _finishSession(false),
          ),
        ],
      ),
      body: Center(child: _buildCardView()),
    );
  }
}
