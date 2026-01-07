# `docs/architecture/exercises.md`

## Objectif

Décrire le **rôle des exercices** dans le moteur d’apprentissage.

Ce document précise :

* ce qu’est un `Exercice`,
* comment il évolue pendant une session,
* comment il interagit avec les mécanismes de progression,
* les invariants à respecter.

Les aspects temporels et l’orchestration sont décrits dans [`sessions.md`](sessions.md).

---

## Rôle d’un Exercice

Un `Exercice` est un **objet runtime stateful**.

Il représente :

* une **interaction utilisateur** avec un contenu pédagogique,
* dans le cadre d’une **session donnée**.

Un exercice :

* est **créé avant** le démarrage de la session,
* est **temporaire** (non persisté),
* encapsule la logique **locale** à cette interaction.

---

## Diagramme conceptuel

```mermaid
%%{init: {"class": {"hideEmptyMembersBox": true}} }%%
classDiagram
    class Exercice
    class WordExercice
    class SentenceExercice
    class ExerciceStatus
    class Grade
    class SRSState
    class SentenceState
    class Word
    class Sentence
    class ExercicePrompt

    Exercice <|-- WordExercice
    Exercice <|-- SentenceExercice

    Exercice "1" --> "1" ExerciceStatus : status
    Exercice "1" --> "1" SRSState : srsState

    WordExercice "1" --> "1" Word : target
    SentenceExercice "1" --> "1..*" Sentence : sentences
    SentenceExercice "1" --> "1..*" SentenceState : updates

    Exercice ..> Grade : applyGrade()
    Exercice ..> ExercicePrompt : getPrompt()
```

---

## Structure générale d’un Exercice

Un `Exercice` encapsule :

* un **état local** intra-session (`ExerciceStatus`),
* un **état de progression** (`SRSState`),
* une logique de réaction aux réponses utilisateur.

Il ne connaît :

* ni la session globale,
* ni l’UI,
* ni la persistence.

---

## ExerciceStatus

`ExerciceStatus` décrit l’**état courant** d’un exercice pendant la session.

Il est utilisé par :

* l’exercice (pour gérer ses transitions),
* la session (pour orchestrer l’ordre de passage).

Exemples typiques de statuts : exercice non encore traité, nouvel exercice, déjà répondu, terminé.

---

## Interaction utilisateur : Grade

Un `Grade` représente la **qualité d’une réponse utilisateur**.

* Il est fourni par la couche applicative.
* Il ne contient aucune logique métier.
* Il est interprété exclusivement par l’exercice.

### Application d’un Grade

Lorsqu’un grade est appliqué à un exercice :

1. L’exercice valide que l’opération est autorisée
   (statut courant compatible).
2. Il met à jour son `ExerciceStatus`.
3. Il met à jour son `SRSState`.
4. Dans le cas d'un `SentenceExercice`, il met à jour des `SentenceState`.

L’exercice est le **seul responsable** de ces mises à jour.

---

## Spécialisations d’Exercice

### WordExercice

Un `WordExercice` :

* cible un `Word`,
* utilise son `SRSState`.

Il ne manipule aucune `SentenceState`.


### SentenceExercice

Un `SentenceExercice` :

* cible un **groupe de phrases** (`Sentence`),
* possède un `SRSState` propre (au niveau du groupe),
* met à jour un `SentenceState` pour chaque phrase concernée.

L'utilisation d'un groupe de phrases permet de :

* avoir un même état **SRS** pour plusieurs phrases proches grammaticalement.
* permettre à l'utilisateur une exposition à de nombreuses phrases sans compromettre la qualité du **SRS**.

---

## Projection d’un Exercice

Un exercice peut produire une **projection immuable de son état**
via `Exercice.getPrompt()`.

Cette projection (`ExercicePrompt`) :

* est créée **à la demande**,
* n’est pas persistée,
* ne contient aucune logique de présentation,
* constitue la seule information exposée à l’UI.

---

## Invariants fondamentaux

* Un exercice est toujours temporaire.
* Un exercice ne persiste aucun état.
* Toute mise à jour de progression passe par un exercice.
* La session ne modifie jamais directement un exercice.
* Un exercice ne connaît ni l’UI ni la persistence.


## Ce que l’Exercice ignore volontairement

Un exercice ignore :

* l’enchaînement global de la session,
* les paramètres utilisateur,
* l’origine des données (DB, API),
* la notion de chapitre.
