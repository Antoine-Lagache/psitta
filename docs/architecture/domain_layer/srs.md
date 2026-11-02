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
and the answer timestamp. `FsrsSchedulerConfig` exposes the 21 model weights,
desired retention, learning and relearning steps, maximum interval, and
fuzzing option. Its defaults use the FSRS defaults, except fuzzing is disabled
so a preview and its submitted answer have the same interval. `SRSConfig`
contains this scheduler configuration as well as session limits and the day
boundary. Parameter optimization is not integrated.

The scheduler owns card memory state. `ExerciseStatus` separately controls the
current session, and `SessionScheduler` decides which exercise is presented
next. `SentenceState` remains independent: it tracks progress for individual
sentences while the containing sentence exercise has one FSRS card.

## Grades

The active `Grade` enum contains the four FSRS ratings and uses their stable
numeric values in history:

| Grade | Stored value | Interpretation |
|---|---:|---|
| Again | 1 | Failed recall |
| Hard | 2 | Successful recall |
| Good | 3 | Successful recall |
| Easy | 4 | Successful recall |

The v3 data migration converts legacy grades before application code reads
them: old Again and hidden legacy Hard both become FSRS Again; old Medium,
Good, and Easy become FSRS Hard, Good, and Easy. Sentence exercises retain
their prior restriction on Easy but now expose FSRS Hard.

## Session behavior

Learning and relearning cards both count as `isInLearning`. A failed review can
therefore remain in the active session for a relearning step. The exercise
completion rule still uses the configured day boundary and whether FSRS has
left its learning/relearning phase. Session limits and the day boundary remain
in `SRSConfig`; the former SM-2 coefficients have been removed from active
configuration.

## Persistence

The v2 migration replays non-training answer history chronologically to derive
each FSRS card. Equal timestamps are ordered by history ID. The v3 migration
then converts historical grade codes to the four FSRS values; timestamps and
history rows remain intact. The card table stores only the current derived
FSRS state. See [FSRS-6 integration](fsrs.md) and the
[database architecture](../persistence_layer/database.md).
