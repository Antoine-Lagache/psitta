[Documentation Index](/docs/index.md)

# SRS Model Invariants

This document lists **all formal invariants** of the SRS model used in the application.

An invariant is a property that **must always hold** to guarantee:
- the mathematical validity of the model,
- the cognitive consistency of its behaviour,
- the absence of undefined states (NaN, negative intervals, etc.).

Invariants are divided into two categories:
1. invariants related to `SRSConfig` (global, static configuration),
2. invariants related to `SRSState` (dynamic, persisted state).

---

## 1. `SRSConfig` Invariants

These invariants concern **only the model configuration**.

They must be verified:
- when a `SRSConfig` is created,
- when loading from persistence,
- when modified via the `SettingsScreen`.

They **must not** be verified on every runtime SRS update.

---

### 1.1. Probabilistic parameters

- For every `λ` in `lambdas`:  
`0 < λ ≤ 1`
- `lambdas.length == 6`

Rationale:
- `λ` is a weighted forgetting factor.
- Outside this range, the weighted success average (`rbar`) becomes unstable or unbounded.
- `lambdas` must provide a value for each `Grade` used by the SRS.
  In the current implementation, this corresponds to a length of 6
  (grades 0 to 5), even if some grades may be unused.

---

### 1.2. Temporal decay parameters

- `mu ≥ 0`

Rationale:
- `mu < 0` would cause memory to strengthen with delay, which is nonsensical.

---

### 1.3. Long pause handling

- `longPause > 0`

Rationale:
- a zero or negative pause has no temporal meaning.

- `0 ≤ minTolFactor ≤ 1`

Rationale:
- tolerance cannot exceed the expected interval,
- nor be negative.

---

### 1.4. Learning phases

- `learningSteps.isNotEmpty`

**Hard** invariant.

- `learningSteps.length > 1`

**Soft** invariant (recommended, but not strictly required).

Rationale:
- an empty or degenerate learning phase has no pedagogical value.

---

### 1.5. Multiplicative factors

- `hardReviewFactor ≥ 1`
- `0 < hardLearningFactor ≤ 1`
- `easyBonus ≥ 1`

Rationale:
- "Hard" must never be more favourable than "Good",
- "Easy" must always accelerate progression.

---

### 1.6. Day boundary

- `dayBoundary < 24h`

Rationale:
- a boundary greater than or equal to 24h makes daily partitioning incoherent.

---

### 1.7. Derived definition (not an invariant)

- `wMax = wMaxFactor × rStar`
- `0 ≤ wMaxFactor < 1`

This relationship is **definitional** and guaranteed by a getter.
It must not be verified dynamically.
The second relation ensures that `w < rStar` and that the logarithmic
expressions in the model are always defined.

---

### 1.8. Default parameters

- `0 < rstar < 1`

`rstar` is a probabilistic parameter representing the target recall probability.

---

- `0 < easyInterval < iMax`

All intervals are in days.

Note:
It is recommended that `easyInterval` be greater than or equal to
the last step in `learningSteps`, to avoid a regression when
graduating with "Easy".

---

- `0 < efMin`

Minimum possible value of `easeFactor`.

---

- `0 < iMax`

Maximum review interval. An interval that is too short has no value but is not forbidden.

---

- `efMin < defaultEF`

Default value of `easeFactor`.

---

- `0 < defaultW ≤ wMax`

Default value of `w`.


---

## 2. `SRSState` Invariants

These invariants concern the **dynamic memorisation state**.

They must be:
- verified regularly,
- corrected where possible,
- signalled (exception / log) when an inconsistency is detected.

Unlike `SRSConfig`, `SRSState` may attempt to **correct certain invariants**
to prevent irreversible corruption.

---

### 2.1. Temporal invariants

- `interval > 0`
- `interval ≤ config.iMax`

Rationale:
- a zero or negative interval is invalid,
- an excessively large interval breaks scheduling.

---

- `lastReview ≤ nextReview`

Rationale:
- time cannot go backwards.

---

### 2.2. Mathematical invariants

- `kFactor > 0`

Rationale:
- `kFactor` is a forgetting rate (unit: `1 / day`),
- required for exponential computation.

---

- `0 ≤ rbar ≤ 1`

Rationale:
- `rbar` is a weighted average of successes.

---

- `0 ≤ w ≤ wMax`

Rationale:
- otherwise the recall probability becomes invalid
  (`log` or exponential undefined).

---

- `efMin ≤ easeFactor`

Rationale: this is a minimum bound.

---

### 2.3. Logical state invariants

- `learningStepIndex == -1`  
**or**
- `0 ≤ learningStepIndex < learningSteps.length`

Rationale:
- no other state is semantically valid.

---

### 2.4. History

- All elements of `history` must be valid `Grade` values.

- `history.isNotEmpty` after at least one effective review.
- `history.length` must match the number of grades effectively applied.

Rationale:
- history is used for:
  - statistics,
  - updating `rbar`.

---

### 2.5. Cross-variable invariants

- `nextReview = lastReview + interval`

Rationale:

`interval` represents the theoretically optimal interval between
`lastReview` and `nextReview`.

By construction:
`nextReview` is computed as `lastReview + interval`
at the moment the SRS is updated, regardless of whether the current
date has exceeded that value.

---

### 2.6. Soft invariants (debug / monitoring)

These invariants **must not** cause failures in production,
but may trigger:
- logs,
- debug assertions.

Examples:
- minor inconsistency between `interval` and `nextReview - lastReview`,
- `nextReview` slightly in the past.

---

## 3. Fundamental Rule

- Invariants **do not correct logic**.
- They **detect** and **signal** violations of assumptions.
- Any automatic correction must be:
  - minimal,
  - documented,
  - followed by a notification (log / error).

---

## 4. What Are Not Invariants

Formulas that must **not** be treated as invariants:

- `w = wMax * rbar`

This is a `w` update equation.
`w` is a stored latent state — it does not strictly depend on `wMax` and `rbar` at all times.

For the same reason, there is no invariant between: `interval`, `easeFactor`, `kFactor`, and `w`.

---

## 5. Recommended Usage

- `SRSConfig`:
  - invariants verified **once** at creation.
- `SRSState`:
  - invariants verified:
    - after construction,
    - after applying a `Grade`,
    - after loading from persistence.

---

This document is the reference for any future SRS evolution.
Any modification to the model must preserve these invariants or explicitly justify their evolution.