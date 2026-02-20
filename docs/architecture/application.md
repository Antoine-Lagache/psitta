# `docs/architecture/application.md`

## Purpose

Describe the **Application / Controllers** layer, which coordinates:

* actions coming from the UI,
* business logic from the **Domain** (sessions, exercises),
* **Persistence** (loading and saving via repositories).

This diagram does not describe the UI or SQL details — only the **structural dependencies**.

---

## Diagram

```mermaid
%%{init: {"class": {"hideEmptyMembersBox": true}} }%%
classDiagram

namespace Application {
  class HomeController
  class SessionController
  class StatsController
  class SettingsController
}

namespace Domain {
  class Session
  class Exercise
  class WordExercise
  class SentenceExercise
  class ExercisePrompt
}


%% Domain inheritance
Exercise <|-- WordExercise
Exercise <|-- SentenceExercise

%% Application -> Domain
HomeController --> SessionController : starts sessions
SessionController --> Session : manages
SessionController --> Exercise : produces/consumes
SessionController --> ExercisePrompt : get projection

%% Application -> Persistence
SessionController --> Repository : **load**<br/> words, groups
SessionController --> Repository : **load/save** SRS

StatsController --> Repository: read

SettingsController --> Repository : read/write config
```

---

## Reading the Diagram

### Controllers (Application)

* `HomeController`: entry-point logic (starting a session, application-side navigation).
* `SessionController`: orchestrates the flow of a session (exercise and session creation; sending `ExercisePrompt` objects to the UI and collecting user input; session teardown).
* `StatsController`: computes and exposes statistics from persisted data, without depending on sessions or the exercise runtime.
* `SettingsController`: exposes and modifies configuration (e.g. SRS parameters).

### Domain

* `Session` orchestrates the exercises of a session.
* `Exercise` is an abstract **runtime** object used during a session. `WordExercise` and `SentenceExercise` are two specialisations.
* `ExercisePrompt` is a projection of an exercise created by the session for the UI. `SessionController` sends them to the UI, which renders them as widgets.

### Persistence

Controllers access data through **repositories**:

* content (`WordRepository`, `SentenceGroupRepository`, `ChapterRepository`)
* progression/config (`SrsRepository`)

SQL, DB mapping, and table definitions are confined to the Persistence diagram.

---

## Architecture Rules

* The UI calls controllers; it never calls the Domain or Persistence directly.
* `StatsController` does not depend on the runtime (sessions/exercises) — only on repositories.
* `SessionController` orchestrates sessions and delegates persistence to repositories (no SQL here).
* The Domain remains independent of the Flutter UI layer.

---

## Note on Controller Lifecycle

**Controllers** are **long-lived** objects, created at application startup and shared across screens.

* They hold dependencies (repositories, configuration).
* They **do not represent** an ongoing session.
* They create and destroy **Session** instances on demand, parameterised by `SessionType`.

**Sessions** are **ephemeral** objects, scoped to the duration of a single learning session.

This decoupling allows multiple sessions to be run sequentially without recreating controllers, and ensures a clear lifecycle management.

* The Application layer knows neither `Widget`, nor Flutter, nor `BuildContext`.