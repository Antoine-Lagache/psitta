[Documentation index](../index.md)

# SRS hypotheses and MVP scope

## Purpose

This document records the non-mathematical assumptions behind Psitta's current
spaced repetition system. These are modelling and product choices, not claims
that the model is cognitively optimal.


## The SRS models a task

One `SRSState` belongs to one exercise, not to an abstract word, sentence, or
language skill. Two tasks using related content may therefore progress
independently, for example recognition and production exercises.

This local model avoids an ill-defined global notion of mastery and keeps the
MVP scheduling state composable. It does not attempt to infer transfer of
knowledge between exercises.

## The response signal is subjective

The user supplies a grade after seeing an exercise. The grade is expected to
summarise correctness, hesitation, and perceived effort.

Measured response duration is not currently part of `ExerciseAnswer` or the SRS
formula. This is a deliberate MVP simplification; it also means the scheduler
cannot independently verify the user's assessment.

## Delay affects failed reviews

In review mode, lateness is used only when the submitted grade is unsuccessful.
A sufficiently late failure weakens or resets the long-term recall estimate
before the normal grade update. A successful late review is not penalised solely
because it was late.

This is a product hypothesis: observed success is considered stronger evidence
than elapsed time. It is not a consequence of the exponential recall formula.

## Exercises are locally independent

The current engine does not model:

- dependencies between vocabulary and grammar;
- prerequisites or knowledge graphs;
- transfer between exercises sharing content;
- a global estimate of the learner's fatigue or ability.

Every answer changes only the selected exercise, its optional sentence state,
its history, and the enclosing session aggregate.

## Sentence exercises represent exposure

A sentence exercise uses two distinct levels of progression:

- one group-level `SRSState` schedules the exercise;
- one `SentenceState` per sentence chooses the least-known example and tracks
  its local exposure.

After the group-level SRS phase completes, a configurable number of successful
consolidation answers may still be required. This design favours repeated
exposure to related sentences without creating an independent SRS schedule for
every sentence instance.

## Session policy

The application layer chooses the session pool by loading at most
`reviewCount` due exercises and `newCount` exercises of the requested type.
Due exercises are prioritised by persisted review time; new exercises are
ordered by identifier.

Inside the session, `SessionScheduler` handles short learning repetitions and
randomises immediately available candidates. The resulting presentation order
is therefore not simply the repository query order.

Sessions can be paused and reconstructed. Persistence stores the session result
and minimal per-exercise resume state; it does not serialize the in-memory
`Session` object.

## Explainability over automatic optimisation

For the MVP, Psitta uses fixed global parameters and deterministic update
formulas. It does not learn parameters from user history and does not implement
a Bayesian or machine-learned memory model.

The following are explicitly outside the current scope:

- automatic per-user parameter fitting;
- cross-exercise knowledge inference;
- probabilistic uncertainty estimates;
- fatigue-aware session adaptation;
- recommendation across different learning activities.

These capabilities may be introduced later, but documentation and code should
not describe them as current behaviour.

## Relationship to the other SRS documents

- [SRS architecture](../architecture/domain_layer/srs.md) explains which
  classes own each responsibility.
- [SRS mathematics](maths_srs.md) describes the implemented formulas and update
  order.
- [SRS validity rules](invariant.md) distinguishes enforced checks from
  configuration assumptions.
