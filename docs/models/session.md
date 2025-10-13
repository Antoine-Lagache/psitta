[⬅️ Retour à la documentation Models](index.md) | [💾 Voir le code source](../../lib/models/session.dart)

# 🧩 `models/session.dart`

## 🎯 Rôle du fichier
Ce module définit la **logique de session d’apprentissage**.  
Une session regroupe les exercices à présenter à l’utilisateur, gère leur ordre, leur disponibilité (`availableAt`) et applique les mises à jour SRS après chaque réponse.

Chaque `Session` est autonome : elle reçoit en entrée une liste d’exercices **nouveaux** et **à réviser**, et détermine dynamiquement la progression de l’utilisateur.

---

## 🔗 Dépendances
```dart
import 'exercice.dart';
import 'srs.dart';
```
> Ce module dépend des classes `Exercice`, `WordExercice`, `SRSState` et `SRSConfig`, nécessaires pour suivre la progression SRS de chaque carte.

---

## 🧩 Contenu principal

### `class Session`

#### 🧱 Propriétés
- `List<Exercice> toDo` — liste des exercices à faire (nouveaux + révisions).  
- `List<Exercice> inProgress` — exercices déjà commencés mais temporairement bloqués (triés par `availableAt`).  
- `List<Exercice> completed` — exercices terminés durant la session.  
- `SRSConfig config` — configuration du système de répétition espacée utilisée pour tous les calculs.  
- `String sessionType` — type de session (par défaut `"Default"`, réservé pour futures extensions).  

#### ⚙️ Constructeur
```dart
Session(List<Exercice> newList, List<Exercice> dueList, this.config, {this.sessionType = "Default"})
  : toDo = buildSessionOrder(newList, dueList);
```
Construit une nouvelle session à partir des listes d’exercices **nouveaux** et **dus**.  
La méthode statique `buildSessionOrder` détermine un ordre équilibré entre révisions et nouveautés.

---

## ⚙️ Méthodes principales

### `_addToInProgressSorted(Exercice exo)`
Insère un exercice dans la liste `inProgress` tout en maintenant l’ordre croissant selon `availableAt`.  
Empêche les doublons et gère les exercices sans date (placés à la fin).


### `chooseExercice()`
Détermine le **prochain exercice à afficher**.  
  1. Priorise les exercices disponibles dans `inProgress` (`availableAt <= now`).  
  2. Sinon, prend le premier élément de `toDo`.  
  3. Si plus rien n’est à faire, retourne `null`.


### `hasNext()`
Retourne `true` si `toDo` ou `inProgress` contiennent encore des éléments.  
Permet de savoir si la session est terminée.


### `submitAnswer(Exercice exo, int grade)`
Applique la logique SRS suite à une réponse utilisateur :  
1. Met à jour le `SRSState` via `applyLearningAnswer` ou `applyReviewAnswer`.  
2. Recalcule la date de disponibilité (`availableAt`) de l’exercice.  
3. Selon la position du **jour limite** (`dayBoundary` du `SRSConfig`),  
   - réinsère l’exercice dans `inProgress` si la prochaine révision est dans la même journée,  
   - ou le déplace dans `completed` sinon.  

Cette méthode est le **cœur de la mécanique de session**.


### `getPreviewInterval(Exercice exo, int q)`
Calcule, sans appliquer de changement, l’intervalle qui serait généré pour une réponse `q`.  
Utilisé pour afficher les durées de révision à venir (prévisualisation des boutons Anki-like).


### `buildSessionOrder(List<Exercice> dueList, List<Exercice> newList)`
Méthode statique utilisée pour créer la liste initiale `toDo`.  
  1. Mélange les deux listes.  
  2. Alterne blocs de révisions et nouvelles cartes selon leur proportion.  
  3. Garantit une répartition équilibrée de la charge cognitive.

---

## 🧠 Comportement global
Une `Session` agit comme un **mini-planificateur** :
1. Initialise la liste d’exercices.  
2. Tire dynamiquement le suivant à faire.  
3. Réévalue les intervalles SRS après chaque réponse.  
4. Gère le repositionnement automatique des exercices selon leur délai.  

Elle ne dépend pas directement de la base de données, ce qui la rend **testable et réutilisable**.

---

_Fichier : `docs/models/session.md` — Documentation du module Session._
