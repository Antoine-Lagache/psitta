[Documentation index](../../index.md)

# Application layer

## Purpose

The Application layer coordinates actions coming from the UI, business logic
from the Domain, and storage operations exposed by Persistence. It contains no
Flutter widgets and no SQL.

---

## Diagram

```mermaid
flowchart TD
    SESSION["SessionController"] --> DOMAIN["Session"]
    SESSION --> REPOSITORIES["Session and Exercise repositories"]
    SESSION --> CONTENT["ContentController"]
    CONTENT --> CONTENT_REPOS["Content and Media repositories"]
    STATS["StatisticController"] --> STAT_REPOS["Session and History repositories"]
```

---

## Controllers

### `SessionController`

`SessionController` owns at most one active `Session`. It implements the
application workflow for:

- loading due and new exercises of the requested session type;
- starting or resuming a session;
- loading the content selected by the current exercise;
- previewing an interval and submitting a grade;
- pausing or ending the session;
- persisting progression after each accepted answer.

Exercise limits and SRS parameters currently come from the default `SRSConfig`
owned by the controller.

### `ContentController`

`ContentController` loads renderable `Content` by identifier and resolves
`Media` by SHA-256. It is used both by session workflows and by the UI media
resolver.

### `StatisticController`

`StatisticController` builds statistics from persisted session results and
answer history. It exposes session-level and exercise-level aggregates, with
optional half-open date ranges.

---

## Application models

The Application layer owns models intended for presentation:

- `Content`, `Field`, `FieldDefinition`, and `FieldValue` describe ordered
  renderable content;
- `Media` identifies a local media resource;
- `SessionStatistics` and `ExerciseStatistics` expose calculated aggregates.

These models are not learning entities. The Domain only manipulates the content
identifier selected by an exercise.

---

## Session workflow

For a new session, the controller loads a limited set of due and new exercises,
constructs and starts the Domain session, then persists its initial resumable
state. After each answer, the Domain is updated first and `SessionRepository`
stores the resulting exercise, history, and session result atomically. It also
refreshes the resume snapshot, or removes it when the session has finished.

Pausing releases the in-memory session after updating its snapshot. Resuming
reconstructs a new Domain `Session` from persisted progression and the snapshot.

---

## Lifecycle and boundaries

Controllers are constructed once by `AppDependencies` and are intended to be
shared by the future screens. A Domain `Session`, by contrast, exists only while
a learning session is active.

- The UI calls controllers rather than repositories.
- Controllers decide when to load and persist data, but learning transitions
  remain in the Domain.
- Persistence models and SQLite rows never enter the Application layer.
- Controllers currently depend on concrete repositories; no repository
  interface abstraction exists yet.
