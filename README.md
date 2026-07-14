# Psitta

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-orange)]()

**psitta** is a cross-platform Flutter application built around a custom Spaced Repetition System (SRS) inspired by the SM-2 algorithm. The goal is not just to ship a language learning app — but to engineer a rigorous, modular, and extensible study engine with clearly defined architectural boundaries and a formally documented memory model.

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
Flutter screens: Home, Sessions, Statistics, Settings. Contains presentation logic only — no direct access to Domain objects or database code.

### Application / Controllers
Orchestrates application workflows: session lifecycle, navigation coordination, and statistics aggregation. Controllers are long-lived and shared across screens.

### Domain
Pure business logic, fully framework-independent:

- Learning content: `Word`, `Sentence`
- Learning sessions: `Session`
- Exercise abstractions: `abstract Exercise`, `WordExercise`, `SentenceExercise`
- SRS scheduling logic

This layer has zero dependencies on Flutter or SQLite and can be tested in isolation.

### Persistence
Data access through the repository pattern. Responsible for SQL queries, database ↔ domain mapping, and storage optimizations. All storage concerns are strictly confined to this layer.

Full architectural documentation is available in [`docs/architecture/`](docs/index.md).

---

## Spaced Repetition Model

The SRS model is formally documented and covers modeling assumptions, scheduling hypotheses, mathematical formulation, and system invariants.

- [`docs/maths_and_srs/maths_srs.md`](docs/maths_and_srs/maths_srs.md) — mathematical model and scheduling logic
- [`docs/maths_and_srs/hypotheses_et_info_srs.md`](docs/maths_and_srs/hypotheses_et_info_srs.md) — modeling hypotheses and design decisions
- [`docs/maths_and_srs/invariant.md`](docs/maths_and_srs/invariant.md) - formal invariants

The implementation is progressively aligned with this formal specification.

---

## Current Status

The project is under active development. Here is a transparent breakdown of progress:

| Component | Status |
|---|---|
| Layered architecture | ✅ Defined and documented |
| SRS model (formal spec) | ✅ Complete |
| Domain layer — class & method design | ✅ Complete |
| Domain layer — implementation | 🔄 ~60–70% complete |
| Persistence layer | ⏳ Not started |
| Application / Controllers | ⏳ Not started |
| UI | ⏳ Not started |

The current focus is completing the Domain layer implementation and ensuring full conformance with the formal SRS specification. The codebase is being incrementally refactored to strictly conform to the defined architecture.

> Code comments are being progressively translated to English

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

Domain logic and SRS unit tests can be run independently once the domain layer implementation is complete:

```bash
flutter test
```

---

## Roadmap

- [ ] Complete Domain layer implementation
- [ ] Implement Persistence layer (SQLite repositories)
- [ ] Implement Application / Controllers layer
- [ ] Build core UI screens (Home, Session, Statistics)
- [ ] Full integration and end-to-end testing
- [ ] Translate all inline code documentation to English

---

## License

This project is licensed under the MIT License. See the [`LICENSE`](LICENSE) file for details.