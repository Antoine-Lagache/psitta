[Documentation index](../../index.md)

# Spaced repetition system

Psitta now uses FSRS-6 for exercise scheduling. The previous SM-2-derived
implementation is archived in
[the history folder](../../history/srs/srs_state_sm2_v0_1.md); it is not part of
the runtime.

## State and scheduling

Each exercise owns one `SRSState`, which wraps an FSRS `Card`. Its persistent
state consists of the FSRS phase (`learning`, `review`, or `relearning`), the
optional step index, stability, difficulty, due time, and last-review time.
`interval` is derived as `due - lastReview`; an unseen card has no
`nextReview`.

FSRS computes the next card state and due time from the current card, a rating,
and the answer timestamp. The adapter uses the upstream default parameters,
0.9 desired retention, 1- and 10-minute learning steps, a 10-minute relearning
step, a 36,500-day maximum interval, and disabled fuzzing. These are fixed
defaults for now; user-configurable FSRS settings and parameter optimization
are outside this migration.

The scheduler owns card memory state. `ExerciseStatus` separately controls the
current session, and `SessionScheduler` decides which exercise is presented
next. `SentenceState` remains independent: it tracks progress for individual
sentences while the containing sentence exercise has one FSRS card.

## Grades

FSRS accepts four ratings: Again, Hard, Good, and Easy. Psitta's existing
five-value grade enum is temporarily mapped as follows while the database and
UI contract are migrated:

| Stored Psitta grade | FSRS rating | Interpretation |
|---|---|---|
| `again` (q=0) | Again | Failure |
| legacy `hard` (q=2) | Again | Failure |
| `medium` (q=3) | Hard | Successful recall |
| `good` (q=4) | Good | Successful recall |
| `easy` (q=5) | Easy | Successful recall |

This is an explicit semantic mapping; numeric values are not cast between
enums. Sentence exercises continue to reject the grades they do not expose.

## Session behavior

Learning and relearning cards both count as `isInLearning`. A failed review can
therefore remain in the active session for a relearning step. The exercise
completion rule still uses the configured day boundary and whether FSRS has
left its learning/relearning phase. Session limits and the day boundary remain
in `SRSConfig`; the former SM-2 coefficients have been removed from active
configuration.

## Persistence

The migration replays non-training answer history chronologically to derive
each FSRS card. Equal timestamps are ordered by history ID. Original grade and
timestamp events remain in `exercise_history`; the card table stores only the
current derived FSRS state. See [FSRS-6 integration](fsrs.md) and the
[database architecture](../persistence_layer/database.md).
