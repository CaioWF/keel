---
name: plan-writer
description: Use after the spec is clarified to write the technical plan for the active feature into specs/<feature>/plan.md from the plan template, with status:draft frontmatter.
---

# plan-writer

When: spec exists and has been through clarify; before breaking work into tasks.

Template: `.specify/templates/plan-template.md`.

Output: `specs/<active-feature>/plan.md`.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/spec.md` to ground the plan in the approved requirements.
2a. Ground the plan in the real tree: read `docs/codebase-map.md` for the structural map (boundaries, entry points, where this kind of feature goes). If it is absent or stale, run the `codebase-map` skill first, then read it — so `Arquitetura` / `Estrutura de Arquivos` name real paths, not invented ones.
2b. If `.specify/impl-conventions.txt` lists any convention lenses (installed by packs such as `stack-conventions`), consult each relevant one and fold its decisions into `Decisões Técnicas` — e.g. naming (code↔DB↔wire), Postgres indexing/RLS, TS type-at-the-boundary. Skip lenses that don't apply to the change. No pack installed ⇒ registry empty ⇒ no-op.
2c. **Replicate before inventing.** Find the closest existing feature/module that already solves this shape of problem (use the map from 2a) and replicate its pattern — same layering, same error/validation strategy, same naming, same file placement. The plan describes how this feature *matches* the established pattern, not a new parallel architecture. Only diverge when the existing pattern genuinely does not fit, and when you do, record the reason in `Decisões Técnicas` — a divergence without a recorded reason is over-engineering (laziness ladder degrau 1). If no comparable pattern exists, say so explicitly.
3. Copy `.specify/templates/plan-template.md` to `specs/<active-feature>/plan.md`.
4. Fill each section that exists in the template:
   - `Arquitetura` — main components, data flow, integration with existing systems.
   - `Estrutura de Arquivos` — concrete file/dir paths to add or touch.
   - `Decisões Técnicas` — tech decisions with rationale.
   - `Contrato da Camada de Dados` — fill ONLY when the plan adds/changes a table, column, index, or migration: the code↔schema mapping (`camelCase`↔`snake_case`) and its single mapping site, keys/constraints/types, indexes, and explicit RLS policies (allow-list on the scope column). If the change does not touch the data layer, write `N/A — não toca a camada de dados`. When `postgres-conventions` is installed (`stack-conventions` pack), draw the specifics from it; `migration-safety` reviews the result later.
   - `Ordem de Implementação` — numbered implementation order.
   - `Como Validar` — unit/integration tests and quality checklist.
5. Keep `status: draft` in the frontmatter.

Approval: like the spec, the plan needs a human to flip its frontmatter to `status: approved`. The phase-gate hook requires BOTH `spec.md` and `plan.md` to carry `status: approved` before it allows any code edit — this file does not self-approve.

Next: tasks-writer.
