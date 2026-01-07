# `docs/architecture/srs.md`

## Objectif

Décrire le **fonctionnement du système de répétition espacée (SRS)** et ses règles
d’utilisation dans le moteur d’apprentissage.

Ce document précise :

* le rôle du SRS,
* la responsabilité des classes impliquées,
* la distinction intra-session / inter-session,
* les règles de persistance.

---

## Rôle du SRS

Le SRS est responsable de :

* représenter l’état de mémorisation,
* faire évoluer cet état après chaque réponse,
* calculer un **interval théorique de révision**.

Le SRS :

* ne connaît pas la notion de session,
* ne décide jamais quand une révision a lieu. Il calcule uniquement le moment où une révision serait optimisée.

---

## Diagramme SRS

```mermaid
%%{init: {"class": {"hideEmptyMembersBox": true}} }%%
classDiagram

namespace Runtime {
  class Exercice
  class Grade
  class WordExercice
  class SentenceExercice
}

namespace Progression {
  class SRSState
  class SRSConfig
  class SentenceState
}

Exercice <|-- WordExercice
Exercice <|-- SentenceExercice

Exercice "1" --> "1" SRSState : possède
SentenceExercice "0..*" --> "0..*" SentenceState : met à jour
Exercice ..> Grade : submitAnswer()
SRSState ..> SRSConfig : utilise

```

---

## SRSState

`SRSState` représente l’état de mémorisation d’un exercice.

* Attaché directement à `Exercice`
* Persisté
* Modifié uniquement suite à une réponse utilisateur

Responsabilités :

* interpréter un `Grade`,
* calculer un nouvel état,
* produire un interval théorique.


## SRSConfig

`SRSConfig` regroupe les paramètres du modèle SRS.

* Fourni à la `Session`
* Utilisé lors de la mise à jour du `SRSState`
* Ne contient aucune logique runtime


## SentenceState

`SentenceState` représente l’état d’exposition/usage d’une phrase. Il est mis à jour par les exercices de type SentenceExercice (typiquement un état par phrase du groupe), indépendamment du SRS : il ne calcule pas d’intervalle de révision mais sert au suivi de progression “contextuelle”.

Son Rôle est de garder les informations permettant à `SentenceExercice` de choisir la phrase à afficher. Typiquement : phrase la moins montrée / la moins réussie du groupe.


## Grade

`Grade` représente la qualité d’une réponse utilisateur (ex. échec, réussite partielle, réussite). Il est fourni par la couche applicative, mais son interprétation (effet sur la progression) est entièrement gérée par l’exercice et le SRS.
Certains grades ne sont pas possible pour tous les types d'exercice.

---

## Intra-session vs inter-session

### Interval théorique

Après une réponse, le SRS calcule un interval **indépendant du contexte** :

* minutes
* heures
* jours


### Utilisation intra-session

La `Session` peut utiliser l’interval pour :

* réordonner les exercices,
* reproposer un exercice pendant la session,
* ignorer les intervalles dépassant la session.

La session :

* ne modifie jamais l’interval,
* applique uniquement une politique d’orchestration.

### Utilisation inter-session

En dehors d’une session :

* l’interval sert à planifier la prochaine révision,
* aucune logique de session n’intervient.

---

## Utilisation pratique

### Preview d’interval

La session peut exposer une **prévisualisation d’interval** :

* sans modifier le `SRSState`,
* à des fins d’information utilisateur : l'utilisateur sait quand il reverra le même exercice s’il obtient un grade précis.




### Persistance: Règle fondamentale

Les `SRSState` sont persistés **après chaque réponse utilisateur valide**.

* Le Domain met à jour le SRS
* La couche applicative déclenche la persistance
* Les sessions et exercices ne sont jamais persistés

### Cas mobile

* Une session interrompue est abandonnée
* Les exercices non terminés sont perdus
* Les `SRSState` persistés restent valides
* Les statistiques temporelles sont best-effort

---

## Invariants

* Le SRS calcule uniquement des intervalles théoriques
* Le SRS ne connaît pas la notion de session
* Toute mise à jour du SRS passe par un exercice
* La persistance est immédiate après chaque réponse
