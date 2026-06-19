---
name: constitution-writer
description: Use once per project, before any feature work, to fill out the project constitution (principles, code standards, SDD process) from the constitution template into .specify/memory/constitution.md.
---

# constitution-writer

When: entry point of the SDD flow. Run once per project, before the first feature is brainstormed or specced. Re-run (or edit in place) only when the team's principles or process actually change.

Template: `.specify/memory/constitution.md.tmpl`.

Output: `.specify/memory/constitution.md`.

Steps:
1. Check whether `.specify/memory/constitution.md` already exists. If it does, treat this as an edit, not a fresh fill — read it first and preserve decisions still valid.
2. Copy `.specify/memory/constitution.md.tmpl` to `.specify/memory/constitution.md` if not present.
3. Fill each section that exists in the template:
   - `Princípios` — the project's guiding principles (3+ short statements).
   - `Padrões de Código` — concrete coding conventions with examples.
   - `Processo SDD` — the phases of the SDD flow as practiced in this repo (Investigação e Spec, Implementação, Review e Validação, Merge e Deploy).
4. Keep entries concrete and project-specific — avoid restating the template's bracketed placeholders verbatim.
5. Do not invent a `status:` frontmatter for this file; the constitution has no approval gate.

Next: brainstorming (to shape the first feature idea), then prd-writer.
