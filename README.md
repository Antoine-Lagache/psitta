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
Flutter application shell with loading and retryable startup states, a temporary Home screen, and content rendering support. Feature screens and navigation are in progress. UI code contains presentation logic only and does not directly access Domain objects or database code.

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

Full architectural documentation is available in [`docs/architecture/`](docs/index.md).

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
| UI | 🔄 Bootstrap complete; feature screens in progress |

The current focus is implementing the first MVP screens and connecting them to the existing application controllers while preserving the documented layer boundaries.


---

## Getting Started

> ⚠️ This project is currently a **work in progress**. Core architectural pieces are present, but several features are still being built or stabilized.

**Prerequisites:** Flutter SDK 3.x, Dart 3.x

```bash
git clone https://github.com/Antoine-Lagache/psitta.git
cd psitta
flutter pub get
flutter run
```

Run the test suite with:

```bash
flutter test
```

---

## License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file for details.
