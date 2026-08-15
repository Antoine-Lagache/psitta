[Documentation Index](/docs/index.md)

# 🧮 SRS Model Mathematics

This document describes the formulas and variables used by the SRS engine of the application.

---

## 🔹 Base Model

The retention probability after a delay $t$ is:

$$
P(t) = (1 - w)e^{-k t} + w
$$

We seek the interval $I$ such that $P(I) = R^*$:

$$
I = -\frac{1}{k}\ln\left(\frac{R^* - w}{1 - w}\right)
$$

---

## 🔹 Main Variables

| Symbol | Name (field / param) | Description |
|---:|---|---|
| $R^*$ | `rstar` | target recall probability |
| $k$ | `kFactor` | forgetting coefficient (short-term) |
| $\text{easeFactor}$ | `easeFactor` | ease factor (adjusts $k$ during review) |
| $w$ | `w` | long-term memory weight (determined by $\bar{R}$) |
| $w_{\max}$ | `wMax` (derived) | $w_{\max} = \text{wMaxFactor}\cdot R^*$ |
| $\bar{R}$ | `rbar` | weighted average of recent successes |
| $\lambda_q$ | `lambdas[q]` | weighting factor associated with grade $q$ |
| $\mu$ | `mu` | exponential decay rate during long pauses |
| `longPause` | `longPause` | delay (days) after which state is fully reset |
| `minTolFactor` | `minTolFactor` | minimum tolerance factor for delay |
| $I$ | `interval` | current interval (Duration) |
| `nextReview` | `nextReview` | DateTime of the next scheduled review |
| `lastReview` | `lastReview` | DateTime of the last review |
| `history` | `history` | grade history (list) |
| `learningStepIndex` | `learningStepIndex` | learning step index (-1 = review mode) |
| `learningSteps` | `learningSteps` | learning step durations (List\<Duration\>) |
| `easyInterval` | `easyInterval` | interval in days for "Easy" graduation |
| `hardReviewFactor` | `hardReviewFactor` | multiplier for "Hard" in review mode |
| `hardLearningFactor` | `hardLearningFactor` | multiplier for "Hard" in learning mode |
| `easyBonus` | `easyBonus` | multiplier for "Easy" in review mode |
| `iMax` | `iMax` | maximum interval (days) |
| `defaultEF` | `defaultEF` | default ease factor value |
| `defaultW` | `defaultW` | default `w` value |
| `wMaxFactor` | `wMaxFactor` | factor used to compute $w_{\max}$ |
| `dayBoundary` | `dayBoundary` | duration representing the day boundary (Duration) |

(Verified: all fields present in `SRSState` and `SRSConfig` are listed above.)

---

## 🔹 Parameter Updates

### 1) Weighted success average
After an observation `obs` (1 = success, 0 = failure) and a weight $\lambda_q$ depending on grade $q$:

$$
\bar{R}_{t+1} = \lambda_q\bar{R}_t + (1 - \lambda_q)\,\text{obs}
$$

### 2) Long-term memory
$$
w = w_{\max}\cdot \bar{R},\qquad w_{\max} = \text{wMaxFactor}\cdot R^*
$$

### 3) Forgetting rate adjustment via easeFactor
On a successful review:

$$
k_{\text{new}} = \dfrac{k_{\text{old}}}{\text{easeFactor}}
$$

### 4) Next interval computation
With updated $k_{\text{new}}$ and $w$:

$$
I_{\text{next}} = -\frac{1}{k_{\text{new}}}\ln\left(\frac{R^* - w}{1 - w}\right)
$$

Constraint applied: $I_{\text{next}} \le iMax$ (in days).

---

## 🔹 Long Pause (Delay) Handling and the Role of $\mu$

Let $\Delta t$ be the time elapsed since the last review and $I$ the expected interval. Define:

$$
l = \max(0,\Delta t - I)
$$

Tolerance:

$$
\text{tol} = \min(\text{longPause}, \text{minTolFactor}\cdot I)
$$

- If $l \ge \text{longPause}$ and grade $q < 2$ (review is failed), then reset:
$$
\bar{R}\leftarrow 0,\quad w\leftarrow 0
$$
- Otherwise, if $l > \text{tol}$, apply exponential decay:
$$
\bar{R}_{t+1} = \bar{R}_t \space e^{-\mu l}
$$
  then:
$$
w \leftarrow w_{\max}\cdot \bar{R}_{t+1}
$$

$\mu$ controls the rate of memory loss after a long absence.

Multiplying `wMax` by `Rbar` ensures that `w <= wMax` while avoiding an abrupt discontinuity.

---

## 🔹 Implementation Notes

- Extreme values are clamped to avoid division by zero or invalid logarithms (arguments are clamped in code).
- Transitions between *learning* and *review* mode are handled via `learningStepIndex == -1`.
- Buttons (grades $q\in\{0..5\}$) determine $\lambda$ via `getLambda(q)` and influence both $\bar{R}$ and the evolution of `easeFactor`:
  - Again button: $q=0$
  - Hard button:  $q=2$  → New button, does not exist in Anki
  - Medium button: $q=3$ → Equivalent to Anki's Hard button
  - Good button:  $q=4$
  - Easy button:  $q=5$
- The formulas presented are those implicitly used by `computePreview*` and `apply*` in `SRSState`.

---

## 🔹 Summary Cycle

1. The user gives a grade $q$.
2. Optional decay ($\mu$) applied if delay is significant.
3. Adjustment of $k$ (via `easeFactor`) and update of `easeFactor` if in review mode.
4. Computation of $I_{\text{next}}$ and update of `interval`, `nextReview`, `lastReview`, `history`.
5. Computation/update of $\bar{R}$ and $w$.

---

_File: `docs/maths_and_srs/maths_srs.md` — key formulas and variables of the SRS._