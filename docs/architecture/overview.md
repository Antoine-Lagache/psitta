# `docs/architecture/overview.md`

## Objectif

Décrire l’architecture globale de l’application et les règles de dépendance entre les grands blocs.
Ce diagramme donne une **vue macroscopique** du projet ; les détails internes de chaque bloc sont précisés dans les diagrammes suivants.

---

## Diagramme

```mermaid
flowchart TD
    %% UI
    UI["UI<br/>Screens / Widgets"]

    %% Application
    APP["Application<br/>Controllers"]

    %% Domain (with internal structure)
    subgraph DOM["Domain"]
        DOM_SESS["<u>Sessions</u><br/>Session / SessionResult / SessionType"]
        DOM_EXO["<u>Exercises</u><br/> Exercise (abstract) / WordExercise / SentenceExercise / ExerciseStatus"]
        DOM_ANSWER["<u>Answer</u><br/> ExerciseAnswer (sealed) / RealExerciseAnswer / PrevieExerciseAnswer"]
        DOM_CONTENT["<u>Content</u><br/> Word / Sentence"]
        DOM_SRS["<u>SRS</u><br/> SRSState / SRSConfig / SentenceState / Grade"]
        DOM_PROMPT["ExercisePrompt"]
    end

    %% Persistence
    subgraph PERS["Persistence"]
        REPO["Repositories"]
        DB[(SQLite DB)]
        REPO --> DB
    end

    %% Utils (transversal, no explicit dependencies)
    UTILS["Utils<br/>Pure helpers"]

    %% Main dependencies
    UI --> APP
    APP --> DOM
    APP --> PERS

```

---

## Lecture du diagramme

### UI

Le bloc **UI** regroupe tous les écrans et widgets Flutter.
Il est responsable uniquement de l’affichage et de la gestion des interactions utilisateur.


### Application / Controllers

Le bloc **Application** constitue le point d’entrée de la logique applicative.
Les controllers :

* reçoivent les actions utilisateur depuis l’UI,
* orchestrent les opérations métier,
* coordonnent l’utilisation du Domain et de la Persistence.


### Domain

Le **Domain** regroupe toute la logique métier de l’application.
Il est volontairement représenté comme un **bloc unique**, mais structuré en sous-composants conceptuels :

* **Content**
  Représente le contenu pédagogique (mots, phrases).

* **Exercises**
  Représente les exercices concrets présentés à l’utilisateur.
  Les exercices sont des objets runtime stateful, créés avant la session et détruits à sa fin.
  
  l'UI ne connait les exercices qu'au travers de `ExercisePrompt` qui est une projection d'un `Exercise`.
* **Answers**
  Représente les réponses utilisateur (`ExerciseAnswer`) transmises aux exercices.
* **Sessions**
  Gère l’organisation des exercices en sessions d’apprentissage.
  Les sessions ne font qu'orchestrer les exercices.

* **SRS**
  Implémente la logique de répétition espacée et l’état de progression.

Le Domain est **indépendant de toute technologie** (UI, DB, Flutter, SQLite).


### Persistence

Le bloc **Persistence** est responsable du stockage et de la reconstruction des données du Domain.

* Les **Repositories** exposent une interface métier d’accès aux données.
* La **base SQLite** gère le stockage physique.

Le SQL, le mapping (`toMap / fromMap`) et les détails de persistance sont confinés à ce bloc.


### Utils

Le bloc **Utils** regroupe des fonctions utilitaires pures (dates, conversions, helpers).
Il est transversal et ne fait pas partie de la hiérarchie de dépendances principale.

---

## Règles de dépendance

* L’**UI** dépend uniquement de l’**Application**.
* L’**Application** dépend du **Domain** et de la **Persistence**.
* Le **Domain** ne dépend d’aucune couche technique.
* La **Persistence** ne contient aucune logique métier.
* Le **SQL et le mapping DB** sont confinés à la Persistence.

---

## Notes d’architecture

* Le Domain est présenté comme un bloc unique au niveau global ; sa structure interne est détaillée dans les diagrammes suivants.
* L’Application joue un rôle d’orchestrateur entre l’UI, le Domain et la Persistence.
* Les fonctions utilitaires sont volontairement exclues des dépendances explicites pour préserver la lisibilité du diagramme.
  
### Notes sur la notion de chapitre

* Les Mots et phrases sont organisés par chapitre. Cette notion de chapitre n'existe que dans le `StatsScreen` et le `HomeScreen`.
* Les chapitres structurent le contenu pour l’utilisateur, mais n’interviennent pas dans la logique d’apprentissage et sont donc ignorés par les sessions et le domain.
