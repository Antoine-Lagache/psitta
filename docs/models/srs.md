[⬅️ Retour à la documentation Models](index.md) | [💾 Voir le code source](../../lib/models/srs.dart)

# 🧠 `models/srs.dart`

## 🎯 Rôle du fichier
Ce module implémente tout le cœur du **système de répétition espacée (SRS)** de l’application.  
Il regroupe :

- **`SRSState`** : l’état individuel de progression d’un exercice (intervalle, facteur de facilité, etc.).  
- **`SRSConfig`** : la configuration globale et les constantes contrôlant l’évolution de la mémoire à long terme.

C’est ici que sont codées les formules inspirées de **SM-2** et enrichies par un modèle de **retrievabilité probabiliste** :  
$$P(t) = (1 - w)e^{-k t} + w$$  
où chaque révision ajuste dynamiquement les paramètres de mémoire.

> Plus d'information sur l'algorithme dans [maths_srs.md](maths_srs.md)

---

## 🔗 Dépendances
```dart
import 'dart:math';
import '../services/convert_utils.dart';
```
> Utilise `dart:math` pour les calculs et `convert_utils.dart` pour les conversions vers/depuis la base SQLite.

---

## 🧩 Classes principales




### 🧱 `class SRSState`
Représente l’état SRS d’un **exercice unique** (ex. une carte de vocabulaire).  
Contient les paramètres évolutifs utilisés pour déterminer le moment optimal de la prochaine révision.

#### Propriétés principales
- `DateTime? nextReview` — date de la prochaine révision prévue.  
- `double easeFactor` — facteur de facilité (influence la croissance de l’intervalle).  
- `Duration interval` — intervalle actuel avant la prochaine révision.  
- `double kFactor` — paramètre de déclin exponentiel de la mémoire.  
- `double w` — poids de la mémoire à long terme.  
- `double rbar` — moyenne pondérée des dernières réussites.  
- `DateTime? lastReview` — date de la dernière révision.  
- `List<dynamic> history` — historique des réponses (pour traçabilité).  
- `int learningStepIndex` — position actuelle dans les étapes d’apprentissage (`-1` = mode review).

---

#### Sérialisation
- `toMap(int exerciceId)` — convertit l’état en un `Map` pour insertion SQLite.  
- `factory SRSState.fromMap(Map<String, dynamic> map)` — reconstruit un état depuis la base.

---

#### Méthodes principales
##### **Prévisualisation (sans modification)**
- `computePreviewLearning(int q, SRSConfig config, {List<Duration>? steps})`  
  → Simule l’intervalle qui serait appliqué pour une note `q` lors d’une phase d’apprentissage.  
- `computePreviewReview(int q, SRSConfig config)`  
  → Simule le prochain intervalle en mode révision.

##### **Application réelle (avec mise à jour de l’état)**
- `applyLearningAnswer(int q, SRSConfig config, {List<Duration>? steps})`  
  → Met à jour les paramètres d’un exercice en apprentissage (`learning steps`).  
- `applyReviewAnswer(int q, SRSConfig config)`  
  → Met à jour un exercice en phase de révision classique (ajuste `easeFactor`, `kFactor`, etc.).

---

### ⚙️ `class SRSConfig`
Définit les **paramètres globaux** du modèle SRS et agit comme profil utilisateur.

#### Propriétés principales
- `double rstar` — cible de retrievabilité (souvent 0.9).  
- `double wMaxFactor` — coefficient pour le calcul du poids mémoire maximum.  
- `List<double> lambdas` — coefficients de pondération par note utilisateur.  
- `List<Duration> learningSteps` — durées de chaque étape d’apprentissage initial.  
- `double efMin` — limite inférieure du facteur de facilité.  
- `int iMax` — intervalle maximum (en jours).  
- `double hardReviewFactor`, `hardLearningFactor`, `easyBonus` — multiplicateurs de difficulté.  
- `Duration dayBoundary` — délimitation de la "journée" (comme Anki).  
- `double mu`, `int longPause`, `double minTolFactor` — paramètres de tolérance et d’oubli.  

---

#### Sérialisation
- `toMap()` — sérialise les paramètres pour stockage en base.  
- `factory SRSConfig.fromMap(Map<String, dynamic> map)` — restaure un profil de configuration depuis SQLite.

---

#### Méthodes utilitaires
- `double get wMax => wMaxFactor * rstar` — poids mémoire maximal.  
- `double getLambda(int q)` — renvoie la pondération associée à la note `q`.  

---

## 🧠 Résumé conceptuel
Ce module implémente une version enrichie de **SM-2**, intégrant :
- une pondération continue de la réussite (`rbar`),  
- une séparation nette entre **phase d’apprentissage** et **phase de révision**,  
- une gestion probabiliste du rappel (`w` et `kFactor`),  
- et une adaptation flexible via `SRSConfig`.

L’ensemble rend le système :
- **plus fluide** que le SM-2 classique,  
- **entièrement configurable**,  
- **compatible SQLite**, sans dépendances externes.

---

_Fichier : `docs/models/srs.md` — Documentation du module SRS._
