---
name: tasks-writer
description: Use after the plan is approved to break the active feature's plan into a concrete task checklist, written into specs/<feature>/tasks.md from the tasks template.
---

# tasks-writer

When: plan exists (ideally already `status: approved`, since implementation is gated on it); before implementation starts.

Template: `.specify/templates/tasks-template.md`.

Output: `specs/<active-feature>/tasks.md`.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/plan.md`, particularly `Ordem de Implementação`, to derive the task breakdown.
3. Copy `.specify/templates/tasks-template.md` to `specs/<active-feature>/tasks.md`.
4. Fill each section that exists in the template:
   - `Checklist de Implementação` — one checkbox per top-level task, mirroring the plan's implementation order.
   - `Subtarefas` — break each top-level task into concrete subtasks under its own `### Task N` heading.
   - `Bloqueadores` — known blockers or external dependencies.
   - `Notas` — execution notes worth keeping (constraints, gotchas).
5. Tasks should be scoped so each can be implemented and verified independently (matches the "ONE task" convention used elsewhere in this repo).

Next: analyze, then implement-feature.
