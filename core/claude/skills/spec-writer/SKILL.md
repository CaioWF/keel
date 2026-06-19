---
name: spec-writer
description: Use after the PRD exists to write the functional spec for the active feature into specs/<feature>/spec.md from the spec template, with status:draft frontmatter.
---

# spec-writer

When: PRD done, before planning.

Template: `.specify/templates/spec-template.md`.

Output: `specs/<active-feature>/spec.md`.

Steps:
1. Resolve the active feature: read `.specify/state` (single line, e.g. `001-name`); if absent, fall back to the newest directory under `specs/`.
2. Copy `.specify/templates/spec-template.md` to `specs/<active-feature>/spec.md`.
3. Fill the frontmatter (`status`, `feature`, `date`) and each section that exists in the template:
   - `User Stories` — story + acceptance criterion per story.
   - `Requisitos Funcionais` — numbered functional requirements (RF1, RF2, ...).
   - `Critérios de Aceitação` — Given/When/Then scenarios.
   - `Fora de Escopo` — what this spec explicitly excludes, plus known dependencies.
4. Keep `status: draft` in the frontmatter — do not set it to `approved` yourself.

Approval: the spec is "approved" only when a human flips the frontmatter to `status: approved`. The phase-gate hook (`core/claude/hooks/phase-gate.mjs`) enforces this — it blocks code edits until both `spec.md` and `plan.md` carry `status: approved`.

Next: clarify, then plan-writer.
