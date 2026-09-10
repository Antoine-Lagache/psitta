[Documentation index](../index.md)

# SRS validity rules

## Purpose

This document distinguishes three different kinds of property:

1. values enforced by the `SRSConfig` constructor;
2. state repaired after `SRSState.applyAnswer`;
3. assumptions required for meaningful behaviour but not currently enforced.

Calling every desired property an invariant would be inaccurate: the current
implementation validates only a subset.


## Enforced configuration properties

The `SRSConfig` constructor throws unless

$$
0<R^*<1
\qquad\text{and}\qquad
0<\texttt{wMaxFactor}<1.
$$

Consequently,

$$
0<w_{\max}=\texttt{wMaxFactor}\,R^*<R^*.
$$

The constructor also normalizes `lambdas`:

- the stored list always has length 6;
- supplied values are clamped to $[0,1]$;
- missing positions use defaults;
- the resulting list is unmodifiable.

`learningSteps` is copied into an unmodifiable list, but its length, ordering,
and duration values are not validated.

## Repairs performed after a submitted answer

After `applyAnswer`, `_checkInvariants` repairs the mutable state as follows.

| State | Repair |
|---|---|
| `interval` | Non-finite or non-positive values become one minute; values above `iMax` become `iMax` days |
| `kFactor` | Non-finite or non-positive values become `defaultKFactor` |
| `rbar` | Non-finite values become 0; finite values are clamped to $[0,1]$ |
| `w` | Non-finite values become `defaultW`; finite values are clamped to $[0,wMax]$ |
| `easeFactor` | Non-finite values become `defaultEF`; lower values become `efMin` |
| `learningStepIndex` | Values below -1 become -1; values beyond the step list become its last index |

These repairs are silent: they do not currently emit a log or exception.
They assume that fallback configuration values such as `iMax`,
`defaultKFactor`, `defaultW`, `defaultEF`, and `efMin` are themselves valid.

No equivalent repair runs:

- in the `SRSState` constructor;
- immediately after a state is reconstructed by `SRSStateMapper`;
- during `previewInterval`.

A malformed stored state can therefore exist until a submitted answer reaches
the repair step, and a preview is not a validation operation.

## Properties guaranteed by construction

- `nextReview` is null exactly when `lastReview` is null; otherwise it is
  computed as `lastReview + interval`.
- `isInLearning` is equivalent to `learningStepIndex >= 0`.
- The stored grade set has numeric qualities $\{0,2,3,4,5\}$; quality 1 is not
  a valid `Grade`.
- `SentenceState.gradeWeights` has six positions so it can be indexed by these
  numeric qualities.

Answer history is not stored inside `SRSState`. It is represented separately by
`ExerciseHistoryEntry`, so no SRS invariant can refer to an internal history
length.

## Required configuration assumptions

For mathematically and operationally meaningful behaviour, callers should also
maintain the following constraints even though `SRSConfig` does not yet enforce
them:

- `mu >= 0`;
- `longPause > 0` and `minTolFactor >= 0`;
- `iMax > 0` and `easyInterval > 0`;
- `efMin > 0`, `defaultEF >= efMin`, and `defaultKFactor > 0`;
- `0 <= defaultW <= wMax`;
- every learning step is positive and the steps are ordered as intended;
- `hardReviewFactor > 0`, `hardLearningFactor > 0`, and `easyBonus > 0`;
- `0 <= dayBoundary < 24 hours`;
- `newCount >= 0` and `reviewCount >= 0`.

Stronger model expectations, such as `minTolFactor <= 1`, a non-empty increasing
learning-step sequence, `easyInterval <= iMax`, `hardReviewFactor >= 1`,
`hardLearningFactor <= 1`, or `easyBonus >= 1`, are product choices rather than
mathematical necessities. They should be validated if configuration becomes
user-editable.

## Persistence and enum constraints

The persistence format expects durations as non-negative integer microseconds
and timestamps as parseable ISO-8601 values. Invalid nullable timestamps in SRS
or session state map to null; an invalid required history timestamp prevents
that history entry from being reconstructed.

`Grade`, `ExerciseStatus`, and `SessionType` expose stable numeric codes.
Persistence should use those codes rather than enum declaration order. The
current `SessionResultMapper` still relies on status codes matching list
indices, so changing `ExerciseStatus` codes or order requires updating that
mapping together.

## Recommended evolution

If SRS configuration becomes editable or remotely supplied, validate all
required assumptions at construction and reject invalid data before running a
preview or update. State loaded from persistence should likewise be validated
or repaired explicitly instead of waiting for the next submitted answer.
