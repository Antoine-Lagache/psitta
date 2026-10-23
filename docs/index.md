# Psitta documentation

[Project README](../README.md)

These documents describe the implementation that currently exists in Psitta.
They focus on the architectural boundaries, runtime flows, persistence model,
and SRS rules needed by a developer entering the project.


## Architecture

- [Overview](architecture/overview.md) — layers, dependency directions, and
  application bootstrap.
- [UI](architecture/ui_layer/ui.md) — startup, main navigation, learning
  workflow, statistics, content rendering, audio, and current limits.
- [Application](architecture/application_layer/application.md) — controllers,
  application models, and session use cases.
- [Domain](architecture/domain_layer/domain.md) — the business model and its
  boundaries.
  - [Sessions](architecture/domain_layer/sessions.md) — lifecycle, scheduling,
    pause/resume, and results.
  - [Exercises](architecture/domain_layer/exercises.md) — word and sentence
    exercise behaviour.
  - [SRS](architecture/domain_layer/srs.md) — how scheduling state is used by
    exercises.
- [Persistence](architecture/persistence_layer/persistence.md) — repositories,
  DAOs, mappers, and transaction boundaries.
  - [Database](architecture/persistence_layer/database.md) — database lifecycle
    and version 1 schema.
  - [Bundled database](bundled_database.md) — generation, first-install snapshot,
    and upgrades that preserve user progress.
  - [Repositories](architecture/persistence_layer/repositories.md) — the APIs
    exposed to the application layer.

## Mathematics and SRS

- [Hypotheses and scope](maths_and_srs/hypotheses_and_mvp_scopes.md) — explicit
  product and modelling choices.
- [Mathematical model](maths_and_srs/maths_srs.md) — formulas and implemented
  update order.
- [Validity rules](maths_and_srs/invariant.md) — enforced checks, repairs, and
  configuration assumptions.

- [Native builds](builds.md) — platform workflows, archives and signing limits.

## Maintenance

Each source document has one primary topic and one compact Mermaid diagram.
Keep statements tied to the current code; planned components should be labelled
as planned rather than documented as existing.

`dart run tools/merge_docs.dart` can generate a local `docs/FULL_DOC.md` for
context loading. This duplicate snapshot is ignored by Git; edit the source
documents above.

- [Content sources](content_sources.md) — provenance, notices, and editorial limits.
- [Publication plan](publication_plan.md) — release steps and deferred ideas.

`tools/line_count.dart` is an optional source-size inspection tool.
`tools/update_final_curriculum.py` reproduces the frozen content adapter; its
inputs and historical Git dependency are documented in [bundled database](bundled_database.md).

Some documentation was written with AI assistance and reviewed by the project
author.
