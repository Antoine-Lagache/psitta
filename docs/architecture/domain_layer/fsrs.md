# FSRS-6 integration

The initial integration is staged in `lib/domain/srs/fsrs/srs_state.dart`.
It is not yet connected to exercises, sessions or the database. The application
still uses the legacy SRS until migration and its callers are updated together.

The adapter keeps `SRSState`, `applyAnswer`, `previewInterval`, `interval`,
`lastReview`, `nextReview`, `isInLearning`, cloning and copying. It does not
accept the legacy `SRSConfig`: its coefficients have no FSRS interpretation.
Unseen exercises have null review dates and a zero interval. Timestamps are
normalized to UTC; answers before the last review are rejected. Equal timestamps
are accepted, so migration must establish a stable order for tied history events.
Learning and relearning both count as `isInLearning`.

Defaults are the upstream 21 model coefficients, retention 0.9, learning steps
1 and 10 minutes, relearning step 10 minutes, maximum interval 36500 days.
Fuzzing is disabled so previews and applications at the same instant agree and
history replay is deterministic. Configuration UI/storage comes later.

The temporary grade bridge maps legacy Again/Hard to FSRS Again, Medium to Hard,
Good to Good, and Easy to Easy. These are semantic mappings, not numeric casts.
It must be removed when the four-grade application contract is introduced.

Next integration work: persist native FSRS state, replay scheduling answers only
(exclude training), handle active sessions and migrate grades. Preserve learning
versus relearning, nullable step, stability, difficulty, due and last review.
Do not infer FSRS state from the old ease factor or interval. Review the existing
session completion rule at the day boundary before switching exercise callers.
Only after that switch can the old implementation become a historical document.

Dependency provenance and license are in `third_party/dart_fsrs/UPSTREAM.md`.
