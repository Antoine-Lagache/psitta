[github.com/Antoine-Lagache/psitta](https://github.com/Antoine-Lagache/psitta)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-orange)]()

**Psitta** is a cross-platform Flutter application built around a custom Spaced Repetition System (SRS) inspired by the SM-2 algorithm. The goal is not just to ship a language learning app — but to engineer a rigorous, modular, and extensible study engine with clearly defined architectural boundaries and a formally documented memory model.

This project serves as both a personal deep-dive into Dart/Flutter and a demonstration of clean software architecture applied to a non-trivial domain.

---

## Highlights

- **Custom SRS engine** — scheduling logic inspired by SM-2, with formal mathematical documentation and explicit modeling hypotheses
- **Strict layered architecture** — UI / Application / Domain / Persistence, with enforced separation of concerns
- **Framework-independent domain layer** — pure Dart business logic with no Flutter or SQLite dependencies
- **Designed for extensibility** — modular exercise abstractions (`WordExercise`, `SentenceExercise`) allow new content types to be added without altering core logic
- **SQLite persistence** — repository pattern with clean domain ↔ storage mapping

---

## Architecture

The application follows a four-layer architecture. Each layer has a single, well-defined responsibility and strict dependency rules.

```
┌──────────────────────────────────────┐
│                  UI                  │  Flutter screens — presentation only
├──────────────────────────────────────┤
│         Application / Controllers    │  Session lifecycle, navigation, aggregation
├──────────────────────────────────────┤
│               Domain                 │  Pure business logic — no Flutter, no SQLite
├──────────────────────────────────────┤
│             Persistence              │  Repositories, SQL queries, domain mapping
└──────────────────────────────────────┘
```

### UI
Flutter application shell with retryable startup states, Home, Learning,
Statistics, Settings, and About screens, and typed content rendering for text,
HTML, images, audio, and video. UI code contains presentation logic only and
does not directly access Domain objects or database code.

### Application / Controllers
Orchestrates application workflows: session lifecycle, content loading, persistence coordination, and statistics aggregation. Controllers are long-lived and shared across screens.

### Domain
Pure business logic, fully framework-independent:

- Learning sessions and results: `Session`, `SessionResult`
- Exercise abstractions: `abstract Exercise`, `WordExercise`, `SentenceExercise`
- Sentence progression: `SentenceGroup`, `SentenceInstance`
- SRS scheduling logic

This layer has zero dependencies on Flutter or SQLite and can be tested in isolation.

### Persistence
Data access through the repository pattern. Responsible for SQL queries, database ↔ domain mapping, and storage optimizations. All storage concerns are strictly confined to this layer.

Full architectural documentation is available in [`docs/`](docs/index.md).

---

## Spaced Repetition Model

The SRS model is formally documented and covers modeling assumptions, scheduling hypotheses, mathematical formulation, and system invariants.

- [`docs/maths_and_srs/maths_srs.md`](docs/maths_and_srs/maths_srs.md) — mathematical model and scheduling logic
- [`docs/maths_and_srs/hypotheses_and_mvp_scopes.md`](docs/maths_and_srs/hypotheses_and_mvp_scopes.md) — modeling hypotheses and design decisions
- [`docs/maths_and_srs/invariant.md`](docs/maths_and_srs/invariant.md) - formal invariants

The implemented model and its current MVP assumptions are described by this
formal specification.

---

## Current Status

The project is under active development. Here is a transparent breakdown of progress:

| Component | Status |
|---|---|
| Layered architecture | ✅ Defined and documented |
| SRS model (formal spec) | ✅ Complete |
| Domain layer — class & method design | ✅ Complete |
| Domain layer — implementation | ✅ Complete |
| Persistence layer | ✅ Complete |
| Application / Controllers | ✅ Complete |
| UI | ✅ MVP screens and learning workflow complete |
| Production learning content | ✅ Frozen v0.1 corpus imported on first launch |

The functional MVP shell and its first Japanese corpus are integrated. The
current focus is reviewing that corpus in the app before the v0.1 release.


---

## Getting Started

On first launch, the app creates `psitta.db`, applies the SQLite schema and
imports the bundled v0.1 exercises before opening the main screen. This works
in debug and release builds. A later launch retains the database and progress.

**Prerequisites:** Flutter SDK 3.x, Dart 3.x

```bash
git clone https://github.com/Antoine-Lagache/psitta.git
cd psitta
flutter pub get
flutter run
```

On Debian- or Ubuntu-based Linux systems, native audio compilation may require:

```bash
sudo apt install libasound2-dev
```

The repository currently contains Flutter platform projects for Android,
Linux, and Web. Persistence uses native SQLite and does not support Web. Other
native platforms require their Flutter platform projects and native builds to
be added and verified before they can be claimed as supported.

### Bundled exercises and installation

`assets/content/v0_1/` contains the frozen HTML corpus copied from
`psitta-content` (`chatgpt/editorial-review`, commit
`92ecfebde93fe4f16c473ecb8f08f45c69afd1a1`):

| File | Contents |
|---|---|
| `manifest.json` | Format version, source checksum, counts and compressed/decoded checksums |
| `word_exercises.jsonl.gz` | 1,297 ordered word exercises, each with separate `front_html` and `back_html` |
| `sentence_exercises.jsonl.gz` | 1,428 ordered groups containing 2,629 sentence instances, each with its own front and back |

`ReleaseContentImporter` verifies both files against the manifest, then writes
2,725 exercises and 3,926 content records in one transaction. A failed import
rolls back completely and the startup screen offers a retry. The corpus is
installed only when the exercise table is empty, so existing user progress is
not overwritten. The import creates two HTML field definitions (front/back),
sentence groups, instance states and initial SRS states. Word exercise IDs
follow the word order; sentence exercise IDs follow the group order. The
learning session may shuffle its selected exercises.

Existing development installations with synthetic exercises keep their data;
to test a clean install, clear application data or remove `psitta.db` from the
application-support directory. `DevelopmentDataSeeder` remains available to
test media rendering explicitly, but is no longer called on normal startup.

The import is a one-time installation of v0.1. Updating a populated database
to a revised corpus will need a versioned content migration that preserves
learning progress.

Run the same checks as CI with:

```bash
dart format lib test tools
flutter analyze
flutter test
```

---

## License

The application code is licensed under MIT; see [`LICENSE`](LICENSE).
The bundled learning content has separate source licenses. JMdict and OpenJLPT
use CC BY-SA 4.0, and the underlying Tatoeba sentences use CC BY 2.0 France.
The Psitta learning-content compilation and adaptations use CC BY-SA 4.0.
Full credits (including OpenJLPT's upstream sources), license texts and JMdict
documentation are bundled offline under `assets/legal/` and accessible through
**Settings → About Psitta → Sources and licenses**. See
[content sources](docs/content_sources.md) for provenance and maintenance notes.
