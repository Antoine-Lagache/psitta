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

`FsrsSchedulerConfig` exposes the 21 weights, desired retention, learning
steps, relearning steps, maximum interval, and fuzzing setting. The defaults
match dart-fsrs for all fields except fuzzing, which is disabled so a preview
and submitted answer remain deterministic. The config is carried by
`SRSConfig`; sessions can override it without changing the vendored package.

## Database migration

V2 reads the exercise IDs and answer history before replacing the legacy SRS
table, then writes one card per exercise. It excludes `consolidating` training
events and replays the remaining events by `(exercise_id, answered_at, id)`.
Legacy q=0 and q=2 map to FSRS Again; q=3, 4, and 5 map to Hard, Good, and
Easy. After replay, the same V2 migration updates every retained history row
to the stable rating values 1–4. It validates rows excluded from replay too,
including sentence-training answers, before changing the schema. New cards
without review history keep FSRS's initial learning state.

The new persistence row stores the FSRS state value, nullable step, stability,
difficulty, and due/last-review timestamps as UTC microseconds. Persisted due is
always present; last review is null until the first answer. The card's current
state is derived from legacy answer history at migration time; history grades
are re-encoded after replay while timestamps and rows remain intact.

Parameter optimization is not integrated. The configuration can override
weights and scheduler settings, but no optimizer computes personalized weights.

Dependency provenance and license are in `third_party/dart_fsrs/UPSTREAM.md`.
