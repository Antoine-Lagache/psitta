# Invariants du modèle SRS

Ce document liste **tous les invariants formels** du modèle SRS utilisé dans l’application.

Un invariant est une propriété qui **doit toujours être vraie** pour garantir :
- la validité mathématique du modèle,
- la cohérence cognitive du comportement,
- l’absence de comportements indéfinis (NaN, intervalles négatifs, etc.).

Les invariants sont divisés en deux catégories :
1. invariants liés à `SRSConfig` (configuration globale, statique),
2. invariants liés à `SRSState` (état dynamique, persisté).

---

## 1. Invariants de `SRSConfig`

Ces invariants concernent **uniquement la configuration du modèle**.

Ils doivent être vérifiés :
- à la création d’un `SRSConfig`,
- lors du chargement depuis la persistence,
- lors de la modification via le `SettingsScreen`.

Ils **ne doivent pas** être vérifiés à chaque mise à jour du SRS runtime.

---

### 1.1. Paramètres probabilistes

- Pour tout `λ` dans `lambdas` :  
`0 < λ ≤ 1`
- `lambdas.length == 6`

Justification :
- `λ` est un facteur d’oubli pondéré.
- Hors de cet intervalle, la moyenne pondérée des succès (`rbar`) devient instable ou non bornée.
- `lambdas` doit fournir une valeur pour chaque `Grade` utilisé par le SRS.
Dans l’implémentation actuelle, cela correspond à une longueur de 6
(notes de 0 à 5), même si certaines notes peuvent être inutilisées.

---

### 1.2. Paramètres de décroissance temporelle

- `mu ≥ 0`

Justification :
- `mu < 0` entraînerait un renforcement de la mémoire avec le retard, ce qui est absurde.

---

### 1.3. Gestion des longues pauses

- `longPause > 0`

Justification :
- une pause nulle ou négative n’a aucun sens temporel.

- `0 ≤ minTolFactor ≤ 1`

Justification :
- la tolérance ne peut pas excéder l’intervalle attendu,
- ni être négative.

---

### 1.4. Phases d’apprentissage (learning)

- `learningSteps.isNotEmpty`

Invariant **fort**.

- `learningSteps.length > 1`

Invariant **souple** (recommandé, mais non strictement requis).

Justification :
- un learning vide ou dégénéré n’a pas d’intérêt pédagogique.

---

### 1.5. Facteurs multiplicatifs

- `hardReviewFactor ≥ 1`
- `0 < hardLearningFactor ≤ 1`
- `easyBonus ≥ 1`

Justification :
- “Hard” ne doit jamais être plus favorable que “Good”,
- “Easy” doit toujours accélérer la progression.

---

### 1.6. Frontière de jour

- `dayBoundary < 24h`

Justification :
- une frontière supérieure ou égale à 24h rend le découpage journalier incohérent.

---

### 1.7. Définition dérivée (non invariant)

- `wMax = wMaxFactor × rStar`
- `0 ≤ wMaxFactor < 1`

Cette relation est **définitionnelle** et garantie par un getter.
Elle ne doit pas être vérifiée dynamiquement.
La deuxième relation garantit que `w < rStar` et que les expressions
logarithmiques du modèle sont toujours définies.


---

### 1.8. Paramètres par défaut

- `0 < rstar < 1`
  
`rstar` est un paramètre probabiliste, il représente la probabilité de rappel.

---

- `0 < easyInterval < iMax`

Tous les intervals sont en jour.

Note :
Il est recommandé que `easyInterval` soit supérieur ou égal
à la dernière étape de `learningSteps`, afin d’éviter une
régression lors d’une graduation "Easy".

---

- `0 < efMin`

Valeur possible minimum de `easeFactor`

---

- `0 < iMax`

Interval maximium de révision. Un interval trop cours n'a aucun interet mais n'est pas interdit.

---

- `efMin < defaultEF`
  
  Valeur par défaut de `easeFactor`


---

- `0 < defaultW ≤ wMax`

Valeur par défautr de `w`

---

### 1.9. Paramètres suspects / à clarifier

- `firstIntervalFallback`

Ce paramètre n’a actuellement **aucun rôle conceptuel clair** dans le modèle
et n’est pas utilisé dans l’implémentation legacy.

Il est considéré comme **candidat à suppression du MVP** tant que son utilité
n’est pas formellement définie.


---

## 2. Invariants de `SRSState`

Ces invariants concernent **l’état dynamique de mémorisation**.

Ils doivent être :
- vérifiés régulièrement,
- corrigés si possible,
- signalés (exception / log) lorsqu’une incohérence est détectée.

Contrairement à `SRSConfig`, `SRSState` peut tenter de **corriger certains invariants**
afin d’éviter une corruption irréversible.

---

### 2.1. Invariants temporels

- `interval > 0`
- `interval ≤ config.iMax`

Justification :
- un interval nul ou négatif est invalide,
- un interval trop grand casse la planification.

---

- `lastReview ≤ nextReview`

Justification :
- le temps ne peut pas reculer.

---

### 2.2. Invariants mathématiques

- `kFactor > 0`

Justification :
- `kFactor` est un taux d’oubli (unité : `1 / day`),
- nécessaire au calcul exponentiel.

---

- `0 ≤ rbar ≤ 1`

Justification :
- `rbar` est une moyenne pondérée de succès.

---

- `0 ≤ w ≤ wMax`

Justification :
- sinon la probabilité de rappel devient invalide
(`log` ou exponentielle non définis).

---

- `efMin ≤ easeFactor`
  
  Justification : c'est un min

---

### 2.3. Invariants d’état logique

- `learningStepIndex == -1`  
**ou**
- `0 ≤ learningStepIndex < learningSteps.length`

Justification :
- aucun autre état n’est sémantiquement valide.

---

### 2.4. Historique

- Tous les éléments de `history` doivent être des `Grade` valides.

- `history.isNotEmpty` après au moins une review effective.
- `history.length` doit correspondre au nombre de grades effectivement appliqués

Justification :
- l’historique est utilisé pour :
- les statistiques,
- la mise à jour de `rbar`.

---

### 2.5. Invariants corélés à plusieurs variables

-  `nextReview = lastReview + interval`

Justification :

`interval` représente l’interval théorique optimal entre
  `lastReview` et `nextReview`.
  
Par construction :
`nextReview` est calculé comme `lastReview + interval`
au moment de la mise à jour du SRS, indépendamment du fait
que la date courante dépasse cette valeur.


---

### 2.6. Invariants souples (debug / monitoring)

Ces invariants ne doivent **pas** provoquer d’échec en production,
mais peuvent déclencher :
- des logs,
- des assertions en debug.

Exemples :
- incohérence mineure entre `interval` et `nextReview - lastReview`,
- `nextReview` légèrement dans le passé.

---

## 3. Règle fondamentale

- Les invariants **ne corrigent pas la logique**.
- Ils **détectent** et **signalent** les violations d’hypothèses.
- Toute correction automatique doit être :
- minimale,
- documentée,
- suivie d’une notification (log / erreur).

---

## 4. Ne sont pas des invariants :

Liste de formule qui ne doivent etre considéré comme invariant :

- `w = wMax * rbar`

Il s'agit d'une équation de mise à jour de w.
Mais `w` est un état latent stocké, il n'est pas dépendant strictement de `wMax` et de `rbar`.

Pour les même raison, il n'y a pas d'invariant entre : `intervale`, `easeFactor`, `kFactor` et `w`.


---

## 5. Usage recommandé

- `SRSConfig` :
- invariants vérifiés **une seule fois** à la création.
- `SRSState` :
- invariants vérifiés :
  - après construction,
  - après application d’un `Grade`,
  - après chargement depuis la persistence.

---

Ce document fait foi pour toute évolution future du SRS.
Toute modification du modèle doit préserver ces invariants ou justifier explicitement leur évolution.
