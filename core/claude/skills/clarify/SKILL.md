---
name: clarify
description: Use after spec-writer to surface ambiguities or gaps in the active feature's spec.md as explicit questions, then update the spec in place once answered.
---

# clarify

When: right after spec-writer produces a draft spec, before plan-writer starts architecting against it. Re-run any time the spec is reopened and feels ambiguous.

Template: none — this skill operates on the existing spec, it does not fill a fresh template.

Output: `specs/<active-feature>/spec.md` (edited in place; same file, no new file created).

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/spec.md` in full.
3. For each section (`User Stories`, `Requisitos Funcionais`, `Critérios de Aceitação`, `Fora de Escopo`), list concrete ambiguities, missing edge cases, or contradictions as numbered questions.
4. Present the questions; once the user (or available context) answers them, edit `spec.md` directly to resolve each ambiguity — tighten requirements, add missing acceptance criteria, or move newly-excluded items into "Fora de Escopo".
5. Leave the frontmatter `status` untouched (still `draft`) unless the human explicitly approves it elsewhere.

Next: plan-writer.
