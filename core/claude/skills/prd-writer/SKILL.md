---
name: prd-writer
description: Use after brainstorming settles on a feature idea to write the Product Requirements Document for a new feature into specs/<feature>/prd.md from the PRD template, creating the feature's spec folder and marking it active.
---

# prd-writer

When: a feature idea has been shaped (e.g. via brainstorming) and is ready to be written down before any spec/code work starts.

Template: `.specify/templates/prd-template.md`.

Output: `specs/<feature>/prd.md`, where `<feature>` is `NNN-kebab-case-name`.

Steps:
1. Determine the next ordinal `NNN`: list existing `specs/*` directories, take the highest leading number, zero-pad the increment to 3 digits (first feature is `001`).
2. Choose a short kebab-case name for the feature; create `specs/NNN-name/`.
3. Copy `.specify/templates/prd-template.md` to `specs/NNN-name/prd.md`.
4. Fill each section that exists in the template:
   - `Problema` — the problem/opportunity and its impact.
   - `Hipótese` — the solution hypothesis and why it should work.
   - `Usuário/Contexto` — target user, usage scenarios, constraints.
   - `Métrica de Sucesso` — measurable KPI/OKR for success.
   - `Fora de Escopo` — what this phase explicitly excludes.
5. Write `NNN-name` (single line, no trailing content) to `.specify/state` so it becomes the active feature for subsequent skills.

Next: spec-writer.
