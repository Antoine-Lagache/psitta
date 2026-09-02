[Documentation Index](/docs/index.md)

# UI Layer

## Current State

The application shell and screens are not implemented yet. The existing UI code is
limited to generic content presentation:

* `ContentRenderer` selects and renders content fields;
* `FieldRenderer` renders supported field values;
* `MediaResolver` resolves persisted media references.

The first UI flow will use `SessionController` to start, resume, answer, pause, and
complete word or sentence sessions. Statistics will be obtained from
`StatisticController`.

## Dependency Rules

* UI code calls Application controllers rather than repositories or DAOs.
* Business rules remain in the Domain layer.
* SQL and persistence models never enter the UI layer.
* The state-management mechanism will be selected when the application shell is built.
