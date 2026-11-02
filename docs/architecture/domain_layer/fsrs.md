# FSRS-6 integration

The active adapter is `lib/domain/srs/srs_state.dart`. It wraps the vendored,
unmodified `fsrs.Card` and `fsrs.Scheduler` from `third_party/dart_fsrs` and is
used by exercise/session flows and the persistence layer.

## Adapter contract

The adapter keeps Psitta's exercise-facing operations: apply an answer, preview
an interval without mutation, inspect the interval and due time, and clone or
copy card state. It additionally exposes FSRS phase, step, stability, and
difficulty for persistence. Answer times are normalized to UTC, and answers
earlier than the stored last review are rejected. Equal timestamps are allowed;
the database migration establishes deterministic ordering for historical ties.

The adapter uses upstream defaults: the 21 default weights, desired retention
0.9, learning steps of 1 and 10 minutes, one 10-minute relearning step, and a
maximum interval of 36,500 days. Fuzzing is disabled, so interval previews,
answers, and history replay are deterministic. `SRSConfig` currently carries
session limits and the day boundary, not FSRS model parameters.

## Database migration

V2 reads the exercise IDs and answer history before replacing the legacy SRS
table, then writes one card per exercise. It excludes `consolidating` training
events and replays the remaining events by `(exercise_id, answered_at, id)`. The legacy q=2
failure maps to FSRS Again; q=3, 4, and 5 map to Hard, Good, and Easy. New cards
without history keep FSRS's initial learning state.

The new persistence row stores the FSRS state value, nullable step, stability,
difficulty, and due/last-review timestamps as UTC microseconds. Persisted due is
always present; last review is null until the first answer. The card's current state is derived from the immutable
answer history at migration time; history itself is not rewritten.

Parameter optimization is not integrated. FSRS's default weights are used for
all users until a later configuration/optimization feature is designed.

Dependency provenance and license are in `third_party/dart_fsrs/UPSTREAM.md`.
