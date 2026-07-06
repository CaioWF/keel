---
name: implement-and-evaluate
description: Orchestrates the implement-feature, evaluator, fix-runner loop for the active feature until all Criterios de Aceitacao are met and quality gates are green.
---

# implement-and-evaluate

When: analyze has reported clean and spec.md + plan.md both carry `status: approved`; this is the main implementation loop for a feature, run task by task until `tasks.md` is fully checked off.

Template: none — this skill orchestrates other skills, it does not fill or produce a template-based artifact itself.

Output: a fully implemented, gate-green feature with every `tasks.md` checkbox ticked and every `spec.md` `Critérios de Aceitação` scenario passing.

## Mode Selection

Choose the execution mode ONCE, before the loop, by reading `tasks.md` (task count and independence) and `plan.md` (coupling between tasks). This picks how each task is executed in step 2a — see `docs/design-notes/execution-mode-routing.md` for the rationale.

| Signal | Mode | How each task runs |
|---|---|---|
| ≤2 tasks, **or** tightly-coupled (tasks share state / touch the same files) | **inline** | invoke `implement-feature` as a Skill (session model); `fix-runner` inline |
| ≥3 mostly-independent tasks | **dispatch** | delegate the whole task loop to `subagent-driven-development` — fresh implementer subagent per task, tree snapshots, per-role model routing |

Dispatch carries real overhead (tree snapshot, brief file, round-trip, re-integration). It pays off only when parallelism or bulk context-pollution justify it; a short or coupled feature is cheaper inline. When in doubt on a borderline count, prefer inline — the review loop is the same either way.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Loop while `specs/<active-feature>/tasks.md` has unchecked top-level tasks:
   a. Execute the next unchecked task (ONE task per iteration) per the mode chosen above:
      - **inline** → invoke `implement-feature` for that task.
      - **dispatch** → hand the task to `subagent-driven-development`, which owns the snapshot + brief + implementer dispatch + model routing for it; then resume this loop at step 2b with the task's result.
   b. Invoke evaluator to score the relevant `Critérios de Aceitação` against the new state.
   c. If evaluator reports any FAIL, invoke fix-runner, then re-invoke evaluator to confirm.
   d. Repeat b-c until evaluator reports all relevant scenarios PASS and gates are green, then proceed to the next task.
3. Stop the loop early and report the blocker if: the phase-gate blocks an edit (spec/plan not approved), a fix-runner attempt requires scope beyond the current task, or the same scenario fails three iterations in a row without progress.
4. Once all tasks are checked and a final fix-runner pass confirms `.specify/gates/run-gates.sh` is green, run evaluator once more over the full `Critérios de Aceitação` list as a final confirmation before handing off.
5. Do not commit. Accumulate changes; commit happens later, once code-review and the human both sign off.

Next: review-and-simplify.
