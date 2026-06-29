---
name: implement-feature
description: Use after analyze reports clean to implement the active feature's tasks.md, one task at a time with TDD, once spec.md and plan.md both carry status:approved.
---

# implement-feature

When: spec, plan, and tasks all exist for the active feature, analyze reported clean, and a human has flipped both `spec.md` and `plan.md` to `status: approved`. The phase-gate hook (`core/claude/hooks/phase-gate.mjs`) enforces this — it blocks Edit/Write on code files until both carry `status: approved`; it does not check `tasks.md`.

Template: none — this skill writes/edits source and test files per the task breakdown, not a spec-style document.

Output: source + test code for ONE task from `specs/<active-feature>/tasks.md`, plus the corresponding checkbox ticked.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/tasks.md` and pick the next unchecked top-level task (in order — do not skip ahead).
3. Read that task's subtasks plus the relevant slices of `spec.md` (`Requisitos Funcionais`, `Critérios de Aceitação`) and `plan.md` (`Arquitetura`, `Estrutura de Arquivos`, `Decisões Técnicas`) to ground the implementation.
4. If Edit/Write is blocked with a phase-gate error, stop and report it — do not work around the gate; the spec/plan need approval first.
5. Implement with TDD — REQUIRED, follow the `test-driven-development` skill for every subtask. Iron Law: NO production code without a failing test first. Test BEHAVIOR (observable outcomes), never implementation details or mocks. Per subtask: write the failing test, watch it fail for the right reason, then **climb the laziness ladder before writing code** (reuse existing → stdlib → native → installed dep → one-liner → minimum viable; see the `architecture` skill's `minimalism.md`) — never at the cost of validation/data-loss/security/a11y — and write the minimal code to pass, refactor while green. Skipping test-first or asserting on mocks is not allowed — delete and start over.
6. Work ONE task at a time. Do not start the next top-level task in the same pass — stop after the current one is done and tested.
7. Tick the task's checkbox in `tasks.md` once its subtasks are all complete and its tests pass.
8. Do not run `.specify/gates/run-gates.sh` yourself here — that is fix-runner's job — but do not leave the codebase in a state you know fails to compile or run its own tests.

Next: evaluator, then fix-runner, looped via implement-and-evaluate until all tasks are done.
