# 📚 Documentation

This directory contains the complete technical documentation of the project.

The documentation is divided into two main parts:

- **Architecture**, which describes how the application is structured.
- **Mathematics & SRS**, which documents the learning algorithm and its theoretical foundations.

---

# Architecture

## [Overview](architecture/overview.md)

Provides a high-level view of the application's architecture and the dependency rules between the different layers.

## [UI](architecture/ui_layer/ui.md)

Describes the application's screens, their responsibilities, and the controllers they interact with.

## [Application](architecture/application_layer/application.md)

Explains the role of the controllers and how they coordinate the UI, Domain, and Persistence layers.

## [Persistence](architecture/persistence_layer/persistence.md)

Describes the Persistence layer and its role as the boundary between the application and data storage.

### [Database](architecture/persistence_layer/database.md)

Describes the SQLite database schema and the relationships between persisted entities.

### [Repositories](architecture/persistence_layer/repositories.md)

Describes the API exposed by the Persistence layer to the Application layer.

## [Domain](architecture/domain_layer/domain.md)

Introduces the core business model of the application, including sessions, exercises, content, and progression.

### [Sessions](architecture/domain_layer/sessions.md)

Details the lifecycle of a learning session and how it orchestrates exercises.

### [Exercises](architecture/domain_layer/exercises.md)

Describes runtime exercises, their responsibilities, state transitions, and interactions with the SRS.

### [SRS](architecture/domain_layer/srs.md)

Explains how the spaced repetition system integrates into the Domain and how progression is managed.

---

# Mathematics & SRS

## [SRS Hypotheses](maths_and_srs/hypotheses_et_info_srs.md)

Lists the cognitive assumptions, product choices, and scope of the SRS model.

## [SRS Mathematics](maths_and_srs/maths_srs.md)

Presents the mathematical model, formulas, variables, and update equations used by the SRS.

## [SRS Invariants](maths_and_srs/invariant.md)

Defines the formal invariants that every valid `SRSConfig` and `SRSState` must satisfy.

---

Each document focuses on a single aspect of the project to minimise duplication and keep the documentation easy to maintain.

Some parts of this documentation were written with the assistance of AI. All generated content has been reviewed and verified by the project author to ensure consistency and accuracy.