# 🧮 Mathématiques du modèle SRS

Ce document décrit les formules et les variables utilisées par le moteur SRS de l’application.

---

## 🔹 Modèle de base

La probabilité de rétention après un délai $t$ est :

$$
P(t) = (1 - w)\,e^{-k t} + w
$$

On cherche l’intervalle $I$ tel que $P(I) = R^*$ :

$$
I = -\frac{1}{k}\ln\!\left(\frac{R^* - w}{1 - w}\right)
$$

---

## 🔹 Variables principales

| Symbole | Nom (champ / param) | Description |
|---:|---|---|
| $R^*$ | `rstar` | cible de probabilité de rappel |
| $k$ | `kFactor` | coefficient d’oubli (court terme) |
| $\text{easeFactor}$ | `easeFactor` | facteur d’aisance (ajuste $k$ en review) |
| $w$ | `w` | poids de la mémoire long terme (déterminé par $\bar{R}$) |
| $w_{\max}$ | `wMax` (dérivé) | $w_{\max} = \text{wMaxFactor}\cdot R^*$ |
| $\bar{R}$ | `rbar` | moyenne pondérée des succès récents |
| $\lambda$ | `lambdas[q]` | poids de pondération associé à la note $q$ |
| $\mu$ | `mu` | taux de décroissance exponentielle en cas de longue pause |
| `longPause` | `longPause` | délai (jours) après lequel on réinitialise complètement |
| `minTolFactor` | `minTolFactor` | facteur minimal de tolérance pour retard |
| $I$ | `interval` | intervalle courant (Duration) |
| `nextReview` | `nextReview` | DateTime de la prochaine révision prévue |
| `lastReview` | `lastReview` | DateTime de la dernière révision |
| `history` | `history` | historique des notes (liste) |
| `learningStepIndex` | `learningStepIndex` | index de l’étape d’apprentissage (-1 = review) |
| `learningSteps` | `learningSteps` | durées des étapes d’apprentissage (List<Duration>) |
| `easyInterval` | `easyInterval` | intervalle en jours pour "Easy" graduation |
| `hardReviewFactor` | `hardReviewFactor` | multiplicateur pour "Hard" en review |
| `hardLearningFactor` | `hardLearningFactor` | multiplicateur pour "Hard" en learning |
| `easyBonus` | `easyBonus` | multiplicateur pour "Easy" en review |
| `iMax` | `iMax` | intervalle max (jours) |
| `defaultEF` | `defaultEF` | valeur EF par défaut (ease factor) |
| `defaultW` | `defaultW` | valeur w par défaut |
| `wMaxFactor` | `wMaxFactor` | facteur pour calculer $w_{\max}$ |
| `dayBoundary` | `dayBoundary` | durée représentant la frontière de jour (Duration) |

(Vérifié : tous les champs présents dans `SRSState` et `SRSConfig` sont listés ci-dessus.)

---

## 🔹 Mise à jour des paramètres

### 1) Moyenne pondérée des succès
Après une observation `obs` (1 = succès, 0 = échec) et un poids $\lambda$ dépendant de la note $q$ :

$$
\bar{R}_{t+1} = \lambda\,\bar{R}_t + (1 - \lambda)\,\text{obs}
$$

### 2) Mémoire long terme
$$
w = w_{\max}\cdot \bar{R},\qquad w_{\max} = \text{wMaxFactor}\cdot R^*
$$

### 3) Ajustement du taux d’oubli via easeFactor
Lors d’une révision réussie :

$$
k_{\text{new}} = \dfrac{k_{\text{old}}}{\text{easeFactor}}
$$

### 4) Calcul de l’intervalle suivant
Avec $k_{\text{new}}$ et $w$ mis à jour :

$$
I_{\text{next}} = -\frac{1}{k_{\text{new}}}\ln\!\left(\frac{R^* - w}{1 - w}\right)
$$

Limitation appliquée : $I_{\text{next}} \le iMax$ (en jours).

---

## 🔹 Gestion des longues pauses (retard) et rôle de $\mu$

Soit $\Delta t$ le temps écoulé depuis la dernière révision et $I$ l’intervalle attendu. Définir :

$$
l = \max(0,\Delta t - I)
$$

Tolérance :

$$
\text{tol} = \min(\text{longPause},\; \text{minTolFactor}\cdot I)
$$

- Si $l \ge \text{longPause}$ et que la note $q < 2$ (review is failed) alors réinitialisation :
  $$
  \bar{R}\leftarrow 0,\quad w\leftarrow 0
  $$
- Sinon si $l > \text{tol}$ alors décroissance exponentielle :
  $$
  \bar{R}_{t+1} = \bar{R}_t\,e^{-\mu l}
  $$
  puis
  $$
  w \leftarrow w_{\max}\cdot \bar{R}_{t+1}
  $$

$\mu$ contrôle la vitesse de perte de mémoire après une longue absence.

---

## 🔹 Remarques d’implémentation

- Les valeurs extrêmes sont bornées pour éviter divisions par zéro ou logarithmes invalides (on clamppe les arguments dans le code).  
- Les transitions entre mode *learning* et *review* se font via `learningStepIndex == -1`.  
- Les boutons (grades $q\in\{0..5\}$) déterminent $\lambda$ via `getLambda(q)` et influencent à la fois $\bar{R}$ et l’évolution d’`easeFactor`:
  - Bouton Again :  $q=0$ 
  - Bouton Hard :   $q=2$  > Nouveau bouton inexistant sur Anki
  - Bouton Medium : $q=3$  > Equivalent au bouton Hard de Anki
  - Bouton Good :   $q=4$
  - Bouton Easy :   $q=5$
- Les formules présentées sont celles utilisées implicitement par `computePreview*` et `apply*` dans `SRSState`.

---

## 🔹 Cycle résumé

1. L’utilisateur donne une note $q$.  
2. Application éventuelle de la décroissance ($\mu$) si retard important.  
4. Ajustement de $k$ (via `easeFactor`) et mise à jour d’`easeFactor` si en review.  
5. Calcul de $I_{\text{next}}$ et mise à jour de `interval`, `nextReview`, `lastReview`, `history`.
6. Calcul/maj de $\bar{R}$, $w$.  

---

_Fichier : `docs/models/maths_srs.md` — formules et variables clés du SRS._
