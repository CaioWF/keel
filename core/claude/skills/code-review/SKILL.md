---
name: code-review
description: Use after implement-and-evaluate confirms acceptance criteria and gates are green, for a final pre-merge review against the constitution and the checklist template.
---

# code-review

When: implement-and-evaluate has finished — all `tasks.md` boxes checked, all `Critérios de Aceitação` passing, gates green — and the feature is otherwise ready to propose for commit.

Template: `.specify/templates/checklist-template.md`.

Output: the checklist filled out against the actual diff, reported inline (and optionally saved alongside the feature's specs if the user wants a persistent record) — plus a list of any findings that must be fixed before merge.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `.specify/memory/constitution.md` (principles, code patterns, SDD process) and hold the diff against it — flag any violation of a stated principle or code pattern.
3. Read `.specify/templates/checklist-template.md` and walk every item (`Testes`, `Quality Gates`, `Documentação`, `Code Review`, `Deploy`) against the actual state of the repo — do not assume an item is satisfied just because gates passed; verify (e.g. check for stray `console.log`/debug statements, confirm spec.md reflects the final implementation).
4. Report each checklist item as done/not-done with evidence, plus any constitution violations found.
5. Make no code edits — this skill reviews, it does not fix. If a finding is blocking, hand it back to implement-and-evaluate (or fix-runner directly for a small gate-level fix) rather than patching it here.
6. Only once the checklist is clean and no constitution violations remain should you propose the commit message(s) to the user and wait for approval — per the project's commit-at-milestone convention, do not commit yourself.

Next: human review and approval, then commit (proposed by you, executed only after explicit approval).
