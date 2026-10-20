# Bundled initial database

New installations copy `assets/database/psitta.db.gz` into the application
support directory before opening SQLite. Building the snapshot moves the full
content import out of the first launch. The snapshot contains initial learning
state only: no answers, sessions, or personal data.

## Regeneration

From the repository root, using the project's Flutter SDK and locked packages:

```sh
flutter pub get
flutter test tools/build_bundled_database.dart --reporter expanded
flutter test test/infrastructure/persistence/bundled_database_test.dart --reporter expanded
```

Both `assets/database/psitta.db.gz` and its `manifest.json` are generated artifacts
ignored by Git. They are bundled in the application build, but never committed.
Run the generator after cloning and whenever the schema, importer, initial state
or source content changes, before `flutter test`, `flutter run`, or
`flutter build <target>`. The CI workflow generates them before its checks.
The tracked `assets/database/.gitignore` keeps the asset directory available in
a fresh clone so the generator can start with no snapshot present.

The generator uses the same migration registry, release importer, DAOs,
and initial state mappers as the application. There is no second SQL schema or
Python implementation to maintain. It uses `VACUUM INTO` to produce a standalone
SQLite file that includes committed WAL contents, then compresses it and records
its version, size, SHA-256 checksums, source manifest checksum and content counts.

To generate elsewhere (for example when comparing artifacts):

```sh
flutter test tools/build_bundled_database.dart --dart-define=SEED_OUTPUT=build/seed
```

The command uses the Flutter test runner because the existing importer depends
on Flutter's asset API; it loads its inputs from disk through the importer's
injected loader. It is not part of normal `flutter test` discovery under `test/`.

## Installation and recovery

- If `psitta.db` exists, the snapshot is not loaded. Existing user data is kept.
- Otherwise an installation lock serializes copies. The archive and database
  checksums, SQLite header and schema version are checked before publication.
- Bytes are flushed to `psitta.db.installing` and renamed on the same filesystem.
  A process interrupted before publication can retry and overwrite the partial
  temporary file. An archive failure leaves no application database.
- Orphaned SQLite journals beside a missing main database cause an explicit
  error rather than being applied to a fresh snapshot.
- SQLite opens through the usual factory (including foreign keys), then runs
  pending migrations. A database newer than the supported schema is rejected.
- The old import path is retained for an existing, migrated but empty database,
  such as an interrupted installation of an earlier app version. It still uses
  one atomic transaction and skips databases containing exercises.

The rename protects against process interruption. Full durability through sudden
power loss remains dependent on the platform filesystem and directory metadata
persistence. The manifest checks detect accidental corruption; they are not a
signature against a malicious modification of both packaged files.

## Future schema and content changes

For a schema change, add a versioned migration to `createMigrationRunner()` and
regenerate the snapshot. Fresh installations receive the new schema directly;
existing installations run the migration against their own database. Do not
replace a user's database with the newer snapshot.

For a content change, update the JSONL archives and their content manifest, then
regenerate. This updates **new installations only**. Updating existing learners
requires a separate content migration that maps stable exercise identities and
preserves SRS state, history and session references. A database schema version
alone does not describe the corpus version.

The snapshot equivalence test compares all table definitions and rows against a
fresh migration plus import. It also checks the source manifest, foreign keys,
integrity, installation failure/retry, and progression across a future migration.
This test runs in the normal CI suite. It detects stale seeds after changes to
schema, importer, initial state or bundled content. Timing printed by the test is
informational; measure a release build on target devices for user-facing startup
latency. It measures database initialization, not complete UI/media startup.

Development sample seeding remains a separate explicit facility. The release
snapshot is built exclusively from `assets/content/v0_1/`.

## Final editorial reference (2026-10-19)

The tracked content now contains 1,297 words and 1,380 groups (3,452 sentence
instances). It comes from `psitta-content` commit
`a447a6186fe0e8c5fc1d1b3c6ea5ded42ac70367`. To reproduce it:

```sh
# In a checkout of psitta-content at the commit above:
python tools/build_v0_1_final_4_3.py
# In Psitta (with full Git history):
python tools/update_final_curriculum.py ../psitta-content
flutter test tools/build_bundled_database.dart --reporter expanded
```

The adapter reuses the HTML at Psitta commit
`8824eaf3dc8543fb203e76bc3db10809483e1e0c`, indexed by original group and instance.
It verifies the exact final curriculum checksum and preserves every sentence
exactly once. This retains the established typography, aligned furigana, Tatoeba
links and 15 explicitly unverified translation suggestions. Ten lexical cards
receive the reviewed JMdict senses with explicit ChatGPT editorial attribution.
The word 訳 and one remaining sentence annotation change from わけ to やく.
Baseline furigana audit counts are retained as historical metadata only.

Stable source word IDs and original sentence references accompany presentation
ranks in the export. Word links are remapped to the new ranks. The current
importer uses HTML and list order; it does not persist those source IDs or enforce
`recommended_session`. Consequently the editorial 4/3 schedule is a recommendation,
not a guarantee provided by the runtime scheduler.

Existing populated databases are **not** updated. To test these exercises without
losing real progress, use a separate clean installation/profile. Clearing app data
also installs the new corpus on next launch, but deletes local learning progress.
