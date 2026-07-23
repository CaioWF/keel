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
   - `Dependências e Interfaces` — the feature's seams, stated at product level (the
     technical contract belongs in `plan.md`):
     - **Consome** — every input the feature needs to work: data, endpoints, events,
       features it reads from. Name the origin, not just the thing.
     - **Expõe** — what the feature newly offers others: endpoints, events, data,
       screens. If nothing is exposed, write "nada" — an empty seam is a real answer.
     - **Dependências** — coupled features/systems with direction: link sibling features
       as `specs/NNN-nome` and say which blocks which. A feature that cannot ship before
       another must say so here, not discover it at plan time.
   - `Fora de Escopo` — what this phase explicitly excludes.
5. Write `NNN-name` (single line, no trailing content) to `.specify/state` so it becomes the active feature for subsequent skills.

Next: spec-writer.
