---
name: architecture
description: Use when designing the structure of a feature or module (in the plan phase, or when refactoring) to apply language-agnostic engineering principles — Clean Architecture, SOLID, testing strategy, and tactical DDD. Container of guides; each concept is a companion.
---

# architecture — language-agnostic engineering principles

Container for keel's architecture concepts. Language-agnostic: it describes **how
to think about** structure; each language realizes it in its own idiom, and mechanical
enforcement (when it exists) comes from a per-language pack, not from here.

## When to use

- In the **plan-writer** phase, when deciding the feature's layers/modules/boundaries.
- When **refactoring** existing structure, or when `architecture-template.md` is filled in.
- Whenever a dependency or boundary decision comes up.

The non-negotiables already live in the constitution (`## Architecture Principles`, injected on
SessionStart) — this skill is the depth and rationale behind them.

## How to apply (in the SDD chain)

1. Identify the feature's **domain** (entities, business rules) and separate it from what is
   framework/I-O/infra.
2. Apply the **dependency rule**: dependencies point inward (see
   [references/clean-architecture.md](references/clean-architecture.md)).
3. Model the domain with **tactical DDD** when there are invariants/state (see
   [references/ddd-tactical.md](references/ddd-tactical.md)).
4. Check the design against **SOLID** (see [references/solid.md](references/solid.md)) — one
   responsibility per unit, depend on abstraction, not on detail.
5. Plan the tests via the **testing strategy** (see
   [references/testing-strategy.md](references/testing-strategy.md)), which reinforces the
   `test-driven-development` skill (behavior over implementation).
6. Before adding a dep/abstraction/feature, climb the **laziness ladder** (see
   [references/minimalism.md](references/minimalism.md)) — the simplest design that satisfies the
   requirement, without cutting security/validation/data-loss/a11y.

## Concepts

Read the one that applies — they are independent and load on demand.

- [references/clean-architecture.md](references/clean-architecture.md) — layers + dependency rule.
- [references/solid.md](references/solid.md) — the 5 principles as heuristics.
- [references/testing-strategy.md](references/testing-strategy.md) — pyramid/strategy; references `test-driven-development`.
- [references/ddd-tactical.md](references/ddd-tactical.md) — entity, value object, aggregate, repository, domain service.
- [references/minimalism.md](references/minimalism.md) — the laziness ladder; pre-write minimalism (vs `simplify` post-write).

To add a concept, see `docs/design-notes/concepts-layer.md` (the container's recipe).
