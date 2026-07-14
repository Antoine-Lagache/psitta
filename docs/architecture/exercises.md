[Documentation Index](../index.md)

# `docs/architecture/exercises.md`

## Purpose

Describe the **role of exercises** in the learning engine.

This document specifies:

* what an `Exercise` is,
* how it evolves during a session,
* how it interacts with progression mechanisms,
* the invariants to respect.

Temporal aspects and orchestration are described in [`sessions.md`](sessions.md).

---

## Role of an Exercise

An `Exercise` is a **stateful runtime object**.

It represents:

* a **user interaction** with learning content,
* within the context of a **given session**.

An exercise:

* is **created before** the session starts,
* is **temporary** (not persisted),
* encapsulates logic that is **local** to that interaction.

---

## Conceptual Diagram

```mermaid
%%{init: {"class": {"hideEmptyMembersBox": true}} }%%
classDiagram
    class Exercise
    class WordExercise
    class SentenceExercise
    class ExerciseStatus
    class SRSState
    class SentenceState
    class Word
    class Sentence
    class ExercisePrompt
    class ExerciseAnswer
    class RealExerciseAnswer
    class PreviewExerciseAnswer

    Exercise <|-- WordExercise
    Exercise <|-- SentenceExercise

    Exercise "1" --> "1" ExerciseStatus : status
    Exercise "1" --> "1" SRSState : srsState

    WordExercise "1" --> "1" Word : target
    SentenceExercise "1" --> "1..*" Sentence : sentences
    SentenceExercise "1" --> "1..*" SentenceState : updates

    ExerciseAnswer <|-- RealExerciseAnswer
    ExerciseAnswer <|-- PreviewExerciseAnswer

    Exercise ..> ExerciseAnswer : submit / preview answer
    Exercise ..> ExercisePrompt : getPrompt()
```

---

## General Structure of an Exercise

An `Exercise` encapsulates:

* a **local intra-session state** (`ExerciseStatus`),
* a **progression state** (`SRSState`),
* logic for reacting to user responses.

It knows nothing about:

* the global session,
* the UI,
* persistence.

---

## ExerciseStatus

`ExerciseStatus` describes the **current state** of an exercise during the session.

It is used by:

* the exercise (to manage its transitions),
* the session (to orchestrate the presentation order).

Typical status examples: not yet attempted, new exercise, already answered, completed.

---

## User Interaction: ExerciseAnswer

User interactions are modelled by the `ExerciseAnswer` type.

An exercise can receive:

* a **real response** (`RealExerciseAnswer`):
  * resulting from an actual user interaction,
  * applied to the exercise and SRS state.

* a **hypothetical response** (`PreviewExerciseAnswer`):
  * used to simulate interval evolution,
  * with no side effects whatsoever.

The exercise is responsible for:
* validating that the response is permitted,
* delegating the progression update,
* updating its intra-session state.

---

## Exercise Specialisations

### WordExercise

A `WordExercise`:

* targets a `Word`,
* uses its `SRSState`.

It does not manipulate any `SentenceState`.

### SentenceExercise

A `SentenceExercise`:

* targets a **group of sentences** (`Sentence`),
* has its own `SRSState` (at the group level),
* updates a `SentenceState` for each sentence involved.

Using a group of sentences allows:

* a single **SRS** state to cover several grammatically related sentences,
* the user to be exposed to many sentences without compromising **SRS** quality.

---

## Exercise Projection

An exercise can produce an **immutable snapshot of its state**
via `Exercise.getPrompt()`.

This projection (`ExercisePrompt`):

* is created **on demand**,
* is not persisted,
* contains no presentation logic,
* is the only information exposed to the UI.

---

## Core Invariants

* An exercise is always temporary.
* An exercise never persists any state.
* All progression updates go through an exercise.
* The session never directly modifies an exercise.
* An exercise knows neither the UI nor persistence.

---

## What the Exercise Intentionally Ignores

An exercise ignores:

* the global session sequencing,
* user parameters,
* the origin of data (DB, API),
* the concept of chapters.