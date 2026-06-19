---
name: analyze
description: Use after tasks-writer to cross-check the active feature's spec, plan, and tasks for gaps or contradictions before implementation begins. Read-only advisory — makes no code or doc changes.
---

# analyze

When: spec, plan, and tasks all exist for the active feature, right before handing off to implementation. Re-run whenever any of the three documents change.

Template: none — this skill is purely analytical, it does not fill or produce a template-based artifact.

Output: findings reported inline to the user (and/or appended as notes under `tasks.md`'s `Notas` section if persistence is wanted) — no new file is mandated.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/spec.md`, `plan.md`, and `tasks.md` in full.
3. Cross-check:
   - Every functional requirement (`Requisitos Funcionais`) in the spec is covered by at least one task.
   - Every acceptance criterion has a corresponding validation step in the plan's `Como Validar` or a task's subtask.
   - The plan's `Ordem de Implementação` and `tasks.md`'s checklist agree on sequence and scope.
   - No task references something out of scope per `Fora de Escopo` in either spec or PRD.
4. Report findings as a list of gaps/contradictions (or confirm none found). Do not edit spec.md, plan.md, or tasks.md, and do not touch any code — this skill is read-only advisory.
5. If findings require changes, hand back to spec-writer/clarify, plan-writer, or tasks-writer as appropriate rather than fixing them directly.

Next: implement-feature, once analyze reports clean and spec.md + plan.md both carry `status: approved`.
