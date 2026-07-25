---
type: design-note
title: Verification contract
description: Why each feature carries a contract.md mapping AC to proof/command/observable, who writes vs stamps it, and why the gate only warns
---

# Design note: the per-feature verification contract

`specs/<feature>/contract.md` answers one question in one place: **how is this feature proven?**
Environment setup, then per `AC-N` the `proof` (test file), the `command` that runs it, the
`observable` that means success, and a `status`.

## The hole it fills

Before it, the function existed spread across five pieces, none self-contained:

| Piece | What it had | What it lacked |
|---|---|---|
| `spec.md` → `Acceptance Criteria` | the criterion's wording (`AC-N`, Given/When/Then) | no proof, no command |
| gate `eval-spec-fidelity` | AC→task traceability (planning-time) | says a task exists, not that anything was verified |
| skill `evaluator` | scored each AC PASS/FAIL | **ephemeral** — printed inline and vanished; re-derived the whole verification plan every loop iteration |
| `plan.md` → `How to Validate` | three strategy bullets | no command, no setup, no observable |
| `checklist-template.md` | generic pre-merge list | not per-feature, not tied to any AC |

So: nothing was self-contained (verifying meant reassembling spec + plan + tasks + code), no
verdict was durable (the next session saw neither what was checked nor how), no `AC→proof` map
existed, and no artifact said what to bring up before the proofs would run.

## Roles: one writes, another stamps

- **`tasks-writer` authors it.** By then the ACs (spec), the `File Structure` (plan), and the test
  breakdown all exist, and it is the last planning-time step — the contract is complete before
  implementation starts. A dedicated skill was rejected: an extra chain link is scaffolding cost
  with no new information.
- **`evaluator` consumes and stamps it.** It reads the contract as its checklist instead of
  re-deriving verification, runs the declared commands, and writes each verdict back into
  `status:`. It is the only file the evaluator writes.
- **Boundary, explicitly.** The evaluator may write `status:`, sharpen `proof:` to a real
  `path:LINE`, and fix a factually wrong `command:`. It may not touch AC labels, `Environment`,
  or `observable` — those are author-time decisions; a wrong one gets reported, not rewritten.
  This is what the author/verifier split buys: the verifier cannot quietly redefine success to
  match what it found.

`analyze` cross-checks the contract before implementation (every AC declares a runnable proof),
which is where a missing or unrunnable proof is cheapest to fix.

## Why the gate only warns

`eval-spec-fidelity` reports contract coverage **both ways** — an AC with no `## AC-N` section
(verification never declared) and a section for an AC the spec dropped or renumbered (a stale
contract) — and never changes its exit code over either. Two reasons: a hard failure would reject
every feature authored before contracts existed, and mandatory-proof-per-AC is exactly the
over-constraint that kills traceability practices (see below). Only `AC→task` traceability blocks.

Drift also gets a prompt-level check the gate cannot do: the evaluator re-reads each criterion in
the spec and, if it was rewritten so the declared proof no longer proves it, reports drift instead
of re-stamping the old verdict. Status vocabulary carries the same intent: `UNVERIFIED` exists so
a criterion nobody could actually run is never recorded as passing.

## Prior art (scanned 2026-07-25)

- **Requirements traceability matrices** are the 30-year-old version of this artifact, and their
  documented failure mode drove two decisions above: over-traceability becomes a maintenance job
  and teams abandon it within weeks, and trace links drift out of sync because nothing propagates
  changes automatically. Hence warn-only rather than mandatory, reference-don't-copy the AC
  wording, the two-way staleness warning, and an evaluator that updates the doc as a side effect
  of work it was doing anyway — propagation is automatic, not a chore.
- **spec-kit** (whose `.specify/` layout keel inherits) produces a `quickstart.md` during planning
  with prerequisites, setup commands, run/test commands, and expected outcomes — independent
  convergence on the same shape. Naming caution: spec-kit's `contracts/` means *API/interface*
  contracts, not verification. In keel, interface contracts live in the PRD's
  `Dependencies & Interfaces` and the plan's `Data Layer Contract`; `contract.md` is verification
  only, and the template says so.
- **Contract-driven adversarial verification** (arXiv 2605.25665, "Meta-Engineering Harnesses for
  AI-Native Software Production") builds a whole harness around a contract "precise enough for one
  agent to build against and another agent to verify", and reports its own failure modes as
  *contract incompleteness* and *verification-boundary issues* — the two things the coverage
  warnings and the explicit write-boundary target.
- **ProductSpec** records per-run "checked criteria and evals, linked evidence, drift status" and
  gardens the repo for missing evidence and stale revision pins. keel deliberately stops short of
  pinned spec revisions and per-run history.

## Deliberately not done

- **No pinned spec revision / content hash.** It needs a deterministic writer to stamp and compare;
  an LLM computing hashes by hand is a bug waiting to happen. Reconsider if the two-way staleness
  warning proves insufficient in practice.
- **No history of past runs.** The contract carries the current verdict, not a log. The durable
  timeline is ADRs, and the loop's own ledger covers in-flight state.
- **No new phase in the state machine.** `phase()` still derives from prd/spec/plan/tasks;
  `contract.md` gates nothing.

See also: [gates vs skills](gates-vs-skills.md), [execution mode routing](execution-mode-routing.md).
