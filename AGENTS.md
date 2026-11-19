# AI development guidelines for Psitta

## Goal
Use AI for implementation while keeping important product and architectural decisions under explicit joint control.

## Before implementing
- Read the relevant code and existing documentation.
- Identify unspecified behavior, hidden assumptions, and decisions that could affect long-term evolution.
- Present important alternatives, their consequences, and a recommendation. Do not silently resolve a consequential ambiguity.
- Implementation may begin once the user and assistant explicitly agree on the important decisions.

## Decision levels
- **Structural:** persistent data and identity, migrations, public contracts, domain invariants, cross-module behavior, backward compatibility, or hard-to-reverse choices. Discuss and obtain explicit agreement before implementing.
- **Secondary:** local, reversible design choices with limited consequences. Decide autonomously and briefly summarize for user validation.
- **Internal detail:** implementation details with no meaningful external or long-term impact. Decide autonomously.

Classify by consequences, not code size. When uncertain whether a decision is structural, raise it for discussion.

## During implementation
- Preserve agreed invariants and document important ones alongside the relevant architecture or tests.
- If a new structural decision appears, stop the affected part of the implementation and request agreement; independent work may continue.
- Do not interpret passing tests as proof that the intended behavior was correctly understood.
- Test changes proportionately and report relevant limitations, assumptions, and secondary decisions.
- Do not introduce unnecessary process or documentation. Record durable architectural rules, not every implementation detail.

## Review
Before integrating structural changes, explain how the implementation satisfies the agreed behavior and invariants, and flag any remaining open decisions. Do not claim user approval implicitly.
