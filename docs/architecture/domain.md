# `docs/architecture/domain.md`

## Objectif

Décrire le **modèle métier central** et le **déroulement général** du moteur d’apprentissage.

Ce document fixe :

* le vocabulaire du projet,
* les responsabilités majeures (`Session`, `Exercise`, contenu, progression),
* la frontière d’affichage via `ExercisePrompt`.

Les détails d’implémentation sont dans :

* `sessions.md` (cycle de vie et orchestration),
* `exercises.md` (runtime d’un exercice et statuts),
* `srs.md` (progression SRS + progression “exposition” via `SentenceState`).

---

## Diagramme du Domain (vue utile, pas exhaustive)

```mermaid
%%{init: {"class": {"hideEmptyMembersBox": true}} }%%
classDiagram

namespace Content {
  class Word
  class Sentence
}

namespace Runtime {
  class Session
  class Exercise
  class WordExercise
  class SentenceExercise
  class ExerciseStatus
}

namespace Progression {
  class SRSConfig
  class SRSState
  class SentenceState
}

namespace Boundary {
  class ExercisePrompt
}

namespace Answer {
  class ExerciseAnswer
  class RealExerciseAnswer
  class PreviewExerciseAnswer
}


%% Inheritance
Exercise <|-- WordExercise
Exercise <|-- SentenceExercise

%% Session
Session "1" --> "0..*" Exercise : orchestrates
Session "1" --> "1" SRSConfig : config

%% Exercise core
Exercise "1" --> "1" SRSState : srsState
Exercise "1" --> "1" ExerciseStatus : status

%% Targets (content)
WordExercise "1" --> "1" Word : target
SentenceExercise "1" --> "1..*" Sentence : sentences

%% Sentence-specific progression
SentenceExercise "1" --> "1..*" SentenceState : updates

%% Boundary projection (created on demand)
Exercise ..> ExercisePrompt : getPrompt()

%% Answer hierarchy
ExerciseAnswer <|-- RealExerciseAnswer
ExerciseAnswer <|-- PreviewExerciseAnswer

%% Answer consumption
SRSState ..> ExerciseAnswer : apply / preview
```

---

## Lecture rapide du modèle

### 1) Content

* `Word` et `Sentence` sont des **données statiques/immuables** (issues de la DB).
* Elles ne portent pas l’état de progression, mais uniquement le contenu (mots, phrases).
### 2) Progression

* `SRSState` est **attaché à `Exercise`** (pas à `Word` ni à `SentenceExercise`). Il gère la logique de progression inter-session.
* `SentenceState` est **distinct du SRS** et existe **pour chaque `Sentence`** dans un `SentenceExercise`.
* `SRSConfig` est fourni à la `Session` et sert aux mises à jour/preview via les exercices.
### 3) ExerciseAnswer (réponses utilisateur)

Le Domain modélise explicitement les réponses utilisateur via `ExerciseAnswer`, un type scellé qui distingue :
* les réponses réelles (`RealExerciseAnswer`), issues d’une interaction utilisateur effective et appliquées au moteur SRS,
* les réponses hypothétiques (`PreviewExerciseAnswer`), utilisées pour simuler un prochain interval sans effet de bord.

`ExerciseAnswer` est consommé par `Session`, `Exercise` et `SRSState` lors d’une interaction, mais n’est pas un état persistant du Domain.

### 4) Runtime

* `Exercise` est un objet **runtime stateful** : `status`, `srsState`, logique intra-session.
* `WordExercise` et `SentenceExercise` spécialisent uniquement la cible et certaines règles (grades autorisés, mise à jour `SentenceState`, etc.).
* `Session` est un **orchestrateur** : elle enchaîne des exercices et porte le `SRSConfig`.

> Note : `SessionType` (cf [session.md](session.md)) est un détail d’initialisation (validation/cohérence) et n’est pas un état persistant de `Session`.

### 5) Boundary (`ExercisePrompt`)

* `ExercisePrompt` est une **projection immuable** construite **à la demande** via `Exercise.getPrompt()`.
* Il n’est pas persisté.
* Il ne contient **aucune logique de présentation** (pas de widget, pas de layout).

---

## Ce que le Domain ignore volontairement

* UI Flutter (widgets, navigation, layout)
* Persistence (SQL, schéma, mapping)
* Paramètres applicatifs “UX” (ex : préférences d’affichage)
* Organisation du contenu en “chapitres” (c’est une structure d’accès/filtrage côté Application/Stats, pas un besoin du moteur runtime)

---

## Répartition des détails (pour éviter un Domain.md trop gros)

* Détails de `Session` (début/fin, current, ordering, contraintes d’appel) → `sessions.md`
* Détails de `Exercise` (statuts, règles de transitions, allowed grades) → `exercises.md`
* Détails progression (`SRSState`, `SentenceState`, `Grade`, preview/apply) → `srs.md`
