---
name: evaluator
description: Use after implement-feature to score the current implementation against the active feature's spec.md Criterios de Aceitacao, emitting a pass/fail list. Read-only — makes no code changes.
---

# evaluator

When: right after implement-feature finishes a task (or a batch of tasks), before deciding whether to loop back for fixes or move on. Re-run any time the implementation changes.

Template: none — this skill is purely evaluative, it does not fill or produce a template-based artifact.

Output: a pass/fail list reported inline to the user (one line per `Critérios de Aceitação` scenario) — no new file is mandated, no existing file is edited.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/spec.md`, focusing on `Critérios de Aceitação` (the Given/When/Then scenarios).
3. For each scenario, inspect the current implementation and its tests to determine whether the behavior is actually satisfied — read code, run existing tests/build if needed, do not assume from `tasks.md` checkboxes alone.
4. Emit one line per scenario: `PASS` or `FAIL` plus a short reason. Also flag any scenario that has no corresponding test at all.
5. Make no code, test, or doc edits — this skill is read-only. If you spot a fix, describe it instead of applying it.
6. Summarize: overall status is "met" only if every scenario is PASS; otherwise "not met" with the failing list.

Next: fix-runner if any scenario fails or gates are red; otherwise hand control back to implement-and-evaluate to continue with the next task or proceed to code-review.
