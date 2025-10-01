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
    service/
        main_router.dart
        main.dart
```
---

## Fichiers et classes

### 'service/main.dart'
- **Fonction principale**
  - `main()`: lance l’application.
  - class MyApp extends StatelessWidget : créer un MaterialApp

### 'service/main_router.dart'
- **class MainRouter extends StatefulWidget**
  - State_MainRouterState
    - contient une liste final ```List<Widget> _page```
    - contient ```int _currentIndex```
    - contient ```final List<PreferredSizeWidget Function(BuildContext)> _pageAppBars```
    - ```@override build```
---

### 'models/exercice.dart'
- **Classes**
  - `abstract class Exercice`
    - Propriétés: `id`, `type`, `srsData`
    - Méthodes: *(lister les signatures uniquement)*
  - `class WordExercice extends Exercice`
    - Propriétés: `word`
    - Constructeur: avec `super`

---

### `models/word.dart`
- **Classes**
  - `class Word`
    - Propriétés: `id`, `text`, etc.
    - Méthodes: *(liste)*

---

### `models/srs.dart`
- **Classes**
  - `class SRS`
    - Propriétés: `interval`, `easeFactor`, etc.
    - Méthodes: `updateAnswer(...)`
  - `class SRSConfig`
    - Paramètres par défaut: `lambda`, `steps`, etc.
  - `class SRSUpdateResult`
    - Propriétés: `graduated`, `newLearningStepIndex`, `availableAt`, `computedInterval`

---

### `models/session.dart`
- **Classes**
  - `class Session`
    - Propriétés: `exercicesInProgress`, `dayBoundary`, etc.
    - Méthodes: `addExercice(...)`, `getNextExercice()`, etc.
  - **Algorithme intra-session**
    - *(réserver une section pour décrire la logique lorsque tu l’auras définie)*

