[Documentation Index](/docs/index.md)

# SQLite Database

## Purpose

Describe the structure and main relationships of the SQLite database used by the Persistence layer.

The database stores persistent application data such as:

* exercises and their progression,
* learning content,
* sentence groups,
* exercise history,
* session results.

Runtime objects such as `Session` and `Exercise` are not stored directly.

---

## Schema Overview

```mermaid
flowchart LR

    subgraph Exercises
        EXERCISE["exercise"]
        SRS["srs_state"]
        WORD["word_exercise"]
        SENTENCE_EX["sentence_exercise"]
        HISTORY["exercise_history"]

        EXERCISE --> SRS
        EXERCISE --> WORD
        EXERCISE --> SENTENCE_EX
        EXERCISE --> HISTORY
    end

    subgraph Content
        CONTENT["content"]
        VALUES["field_value"]
        DEFINITION["field_definition"]
        MEDIA["media"]

        CONTENT --> VALUES
        DEFINITION --> VALUES
        VALUES --> MEDIA
    end

    subgraph Sentences
        GROUP["sentence_group"]
        INSTANCE["sentence_instance"]
        STATE["sentence_state"]

        GROUP --> INSTANCE
        INSTANCE --> STATE
    end

    subgraph Sessions
        RESULT["session_result"]
        COUNTS["session_result_status_count"]
        ACTIVE["active_session_exercise"]

        RESULT --> COUNTS
        RESULT --> ACTIVE
    end

    WORD --> CONTENT
    SENTENCE_EX --> GROUP
    INSTANCE --> CONTENT
    ACTIVE --> EXERCISE
```

The schema is organised around four main areas:

* **Exercises** — persistent exercise identity and SRS state.
* **Content** — generic content and its fields.
* **Sentences** — groups, sentence instances and sentence-level progression.
* **Sessions** — persistent results produced by completed sessions.

---

## Exercises

An exercise is represented by a base `exercise` row and a type-specific row:

* `word_exercise`
* `sentence_exercise`

The common identity is stored in `exercise`, while type-specific data is stored in the corresponding table.

Each exercise has exactly one `srs_state`.

Exercise responses are recorded separately in `exercise_history`, allowing multiple history entries for the same exercise.

---

## Content

Content is stored independently from exercises.

```mermaid
flowchart LR
    CONTENT["content"] --> VALUES["field_value"]
    VALUES --> DEFINITION["field_definition"]
    VALUES --> MEDIA["media"]
```

A `content` item is composed of one or more field values.

`field_definition` describes what a field represents, while `field_value` stores the value associated with a particular content item.

Media are stored as references to files rather than as binary data inside the database.

---

## Sentences

Sentence exercises operate on groups of sentence instances.

```mermaid
flowchart LR
    EXERCISE["sentence_exercise"]
    GROUP["sentence_group"]
    INSTANCE["sentence_instance"]
    STATE["sentence_state"]

    EXERCISE --> GROUP
    GROUP --> INSTANCE
    INSTANCE --> STATE
```

A `sentence_group` contains several `sentence_instance` objects.

Each instance has its own `sentence_state`, which tracks sentence-level exposure independently from the exercise's `srs_state`.

---

## Session Results

Sessions are runtime objects and are not persisted.

Sessions are reconstructed from their result and active-exercise rows:

```mermaid
flowchart LR
    RESULT["session_result"] --> COUNTS["session_result_status_count"]
    RESULT --> ACTIVE["active_session_exercise"]
    ACTIVE --> EXERCISE["exercise"]
```

`session_result` stores aggregate progress, `session_result_status_count` stores answer
counts, and `active_session_exercise` stores the per-session state required for resume.

---

## Referential Integrity

Foreign keys are enabled in SQLite.

`ON DELETE CASCADE` is used for data that is owned by another entity, such as:

* an exercise and its SRS state,
* an exercise and its history,
* a sentence group and its instances,
* a sentence instance and its state,
* a session result and its status counts.
* a session result and its active exercises.

References to shared `content` do not cascade. Deleting content therefore does not automatically delete the exercises that reference it.

---

## Runtime vs Persistent Data

The database does not reproduce the Domain object graph exactly.

```mermaid
flowchart LR
    DOMAIN["Domain runtime"]
    DB["SQLite"]

    DOMAIN -->|"persistent state"| DB
```

The database stores the information required to reconstruct and continue the application, rather than temporary runtime objects.

In particular:

* `Session` is reconstructed rather than stored as a serialized object.
* `Exercise` runtime state is not persisted directly.
* `SRSState` is persisted.
* Exercise history is persisted.
* Session results are persisted.
