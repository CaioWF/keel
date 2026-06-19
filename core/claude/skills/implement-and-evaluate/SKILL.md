---
name: implement-and-evaluate
description: Orchestrates the implement-feature, evaluator, fix-runner loop for the active feature until all Criterios de Aceitacao are met and quality gates are green.
---

# implement-and-evaluate

When: analyze has reported clean and spec.md + plan.md both carry `status: approved`; this is the main implementation loop for a feature, run task by task until `tasks.md` is fully checked off.

Template: none — this skill orchestrates other skills, it does not fill or produce a template-based artifact itself.

Output: a fully implemented, gate-green feature with every `tasks.md` checkbox ticked and every `spec.md` `Critérios de Aceitação` scenario passing.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Loop while `specs/<active-feature>/tasks.md` has unchecked top-level tasks:
   a. Invoke implement-feature for the next unchecked task (ONE task per iteration).
   b. Invoke evaluator to score the relevant `Critérios de Aceitação` against the new state.
   c. If evaluator reports any FAIL, invoke fix-runner, then re-invoke evaluator to confirm.
   d. Repeat b-c until evaluator reports all relevant scenarios PASS and gates are green, then proceed to the next task.
3. Stop the loop early and report the blocker if: the phase-gate blocks an edit (spec/plan not approved), a fix-runner attempt requires scope beyond the current task, or the same scenario fails three iterations in a row without progress.
4. Once all tasks are checked and a final fix-runner pass confirms `.specify/gates/run-gates.sh` is green, run evaluator once more over the full `Critérios de Aceitação` list as a final confirmation before handing off.
5. Do not commit. Accumulate changes; commit happens later, once code-review and the human both sign off.

Next: review-and-simplify.
