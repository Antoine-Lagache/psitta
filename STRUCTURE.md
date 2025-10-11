# STRUCTURE.md

## Introduction
Brève description du projet, objectifs et organisation générale.

---

## Arborescence des fichiers
```text
lib/
  models/
    exercice.dart
    note.dart
    session.dart
    srs.dart
  playground/
    test.dart
  screen/
    home_screen.dart
    setting.dart
    statistic_screen.dart
  main_router.dart
  main.dart
```
---

## Fichiers et classes

### `main.dart`
- **Fonction principale**
  - `main()`: lance l’application.
  - `class MyApp extends StatelessWidget` : créer un MaterialApp

### `main_router.dart`
- **class MainRouter extends StatefulWidget**
  - State_MainRouterState
    - contient une liste final `List<Widget> _page`
    - contient `int _currentIndex`
    - contient `final List<PreferredSizeWidget Function(BuildContext)> _pageAppBars`
    - `@override build`
---

### `screen/home_screen`
- `class HomeScreen extends StatelessWidget`
  - `@override build`
- `PreferredSizeWidget buildHomeAppBar(BuildContext context)` définie le widget à afficher sur l'AppBar

### `screen/statistic_screen.dart`
- `class StatisticScreen extends StatelessWidget`
  - `@override build`
- `PreferredSizeWidget buildStatisticAppBar(BuildContext context)` définie le widget à afficher sur l'AppBar

### `screen/setting_screen`
- `class SettingScreen extends StatelessWidget`
  - `@override build`
- `PreferredSizeWidget buildSettingAppBar(BuildContext context)` définie le widget à afficher sur l'AppBar

---

### `playground\`
- fichier dart pour des test ou pour appdrendre / découvrir le dart
  
---

### `models/exercice.dart`
- `enum ExerciceType`
  - contient `word` seulement pour l'instant
- `abstract class Exercice`
  - Propriété `final ExerciceType type`
  - Propriété `SRSState srsData`
  - Propriété `DateTime? availableAt;   // moment où l'exercice redevient disponible. null au départ`
- `class WordExercice extends Exercice`
  - Propriétés: `final Card card`
  - constructeur, `type: ExerciceType.word`

### `models/note.dart`
- `class Note`
  - propriété `final Map<String, dynamic> data; \\JSON flexible`
  - propriété `final List<String>? tags;`
  - propriété `final DateTime createdTime;`
- `class CardTemplate`
  - propriété `final String rectoHtml;`
  - prorpiété `final String versoHtml;`
- `class Card`
  - propriété `final Note note;`
  - propriété `final CardTemplate template`

### `models/srs.dart`
- `class SRSState`
  - **propriétés:**
    -  `DateTime? nextReview`
    -  `double easeFactor;`
    -  `Duration interval; // duration for review intervals`
    -  `double kFactor;`
    -  `double w; //correspond à la mémoire long terme`
    -  `double rbar; //moyenne pondéré des dernière victoire`
    -  `DateTime? lastReview;`
    -  `List<int> history; //inutilisé pour l'instant`
    -  `int learningStepIndex; // index in learning steps (-1 = not in learning)`
  - **méthodes:**
    - `Duration computePreviewLearning(int q, SRSConfig config, {List<Duration>? steps})` permet de calculé l'intervalle pour chacun des 5 boutons (Again, Hard, Medium, Good, Easy) dans le cas mode learning
    - `Duration computePreviewReview(int q, SRSConfig config)` calcule l'intervalle quand l'exercice est en mode Review
    - `Duration applyLearningAnswer(int q, SRSConfig config, {List<Duration>? steps})` renvoie l'intervalle et modifie les paramètre dans le cas mode learning
    - `Duration applyReviewAnswer(int q, SRSConfig config)` fait la même chose si l'exercice est en mode review
- `class SRSConfig`
  - **propriétés:**
    - `final double rstar;`
    - `final double wMaxFactor;`
    - `final List<double> lambdas;`
    - `final int easyInterval; // days`
    - `final int firstIntervalFallback; // used for SM-2 first review`
    - `final double efMin;`
    - `final int iMax;`
    - `final double defaultEF;`
    - `final double defaultW;`
    - `final double mu;`
    - `final int longPause;`
    - `final double minTolFactor;`
    - `final List<Duration> learningSteps;`
    - `final double hardReviewFactor;`
    - `final double hardLearningFactor;`
    - `final double easyBonus;`
    - `final Duration dayBoundary; // 0..23, Anki-like day boundary`
  - **constante :**
    - `static const List<double> _defaultLambdas = [0.60, 0.90, 0.80, 0.95, 0.85, 0.70];`
  - **getter :**
    - `double get wMax => wMaxFactor * rstar;` rappel : `w := Rbar * wMax`
    - `double getLambda(int q)` renvoie le lambda correspondant à la note q donnée par l'utilisateur. C'est à dire que la moyenne pondérer Rbar n'est pas pondérer par le meme poids lambda en fonctions q.

### `models/session.dart`
- `class Session`
  - **Propriétés:**
    - `final List<Exercice> toDo; // liste simple, pas de timer`
    - `final List<Exercice> inProgress = []; // maintenue triée par availableAt asc`
    - `final List<Exercice> completed = [];`
    - `final SRSConfig config;`
    - `String sessionType; //inutilisé pour l'instant`
  - **Méthodes:**
    - `void _addToInProgressSorted(Exercice exo)  // helper: insert en maintenant la liste triée par availableAt` 
    - `Exercice? chooseExercice() //choisi l'exercice suivant`
    - `bool hasNext()` Renvoie true si toDo ou inProgress non vide.
    - `void submitAnswer(Exercice exo, int grade) // submitAnswer applique toujours update SRS et gère learning steps.`
    - `Duration getPreviewInterval(Exercice exo, int q)` utilise les méthodes `exo.srsData.computePreviewReview` ou `exo.srsData.computePreviewLearning` pour obtenir le résultat.
    - `static List<Exercice> buildSessionOrder(List<Exercice> dueList, List<Exercice> newList)` est utilisé par le constructeur pour obtenir la liste toDO à partir des exercices à réviser et des nouveaux exercices.


---

## modèle SRS

Probabilité de rétention après un temps t :
$$P(t) = (1-w) exp(-kt) + w \\$$
avec :
$$P(I) = R^*$$