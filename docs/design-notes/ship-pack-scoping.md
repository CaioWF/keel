# Ship-pack scoping

Scoping note for a possible `ship` pack — the lifecycle phase keel's chain deliberately
stops short of. The SDD chain ends at `finishing-a-development-branch` (merge / PR /
keep / discard); everything after the branch integrates — deploy, run, observe, deprecate —
is currently out of scope. addyosmani/agent-skills (MIT) has a full **Ship** phase; this
note sorts its five skills into *what fits keel's agnostic-core philosophy* vs *what does
not*, so the human can green-light a scoped build rather than porting all five.

## The tension

keel is an SDD **authoring** framework: agnostic process core + stack/domain **packs**,
mechanical enforcement via gates/hooks. Its value is in the *judgment* it encodes, not in
environment plumbing. So the filter for each Ship skill is: **is the discipline agnostic
and judgment-shaped (keel-fit), or environment-specific plumbing (not keel-fit)?**

## Per-component verdict

| addyosmani skill | keel status | Verdict |
|---|---|---|
| **observability-and-instrumentation** | no equivalent; DoD companion already *references* observability with nothing behind it | **INCLUDE** — agnostic, judgment-shaped (define the 2–4 on-call questions, RED metrics, symptom-not-cause alerts, never log secrets/PII). Strongest fit. |
| **deprecation-and-migration** | `migration-safety` pack covers DB migration; API/contract deprecation is a gap | **INCLUDE (scoped)** — add the *contract-deprecation* discipline (deprecate→warn→sunset, backward-compat window) that extends, not duplicates, `migration-safety`. |
| **documentation-and-adrs** | ADR infra (`core/docs/architecture/adr`) + `architecture` skill already exist | **SKIP** — mostly covered. At most a thin doc-sync reminder, not a new skill. |
| **shipping-and-launch** | DoD `## Ship-readiness` already lists rollback/flags/approval | **SKIP for now** — thin overlap with the DoD companion; fold anything missing into DoD instead of a new skill. |
| **ci-cd-and-automation** | none; `run-gates.sh` detects build stack-independently | **SKIP** — environment-specific (GH Actions vs GitLab vs …). Poor agnostic fit; if wanted, a *knowledge doc* of patterns, never a mechanical skill. |

## Recommended scope (if built)

A **lean** `ship` pack, not a five-skill port:

1. `observability-and-instrumentation` skill (+ `observability-checklist.md` companion from the
   agent-skills reference) — the one clear win. Wire it into the DoD ship-readiness item so the
   existing reference points at a real skill.
2. `contract-deprecation` skill — scoped to public interface/API deprecation, cross-referenced
   with the `migration-safety` pack so DB and contract concerns compose without overlap.

Defer ci-cd, shipping-launch, documentation-and-adrs per the verdicts above.

## Open decision (human)

Does shipping belong in keel at all, or is "stops at integrate" a deliberate boundary worth
keeping? If keep-the-boundary: close #4 as **won't-do** and instead just point the DoD
observability/rollback lines at external guidance. If grow-the-phase: build the two-skill lean
pack above, gated behind `--pack=ship` (opt-in, never auto-detected).

Recommendation: **build the lean pack, opt-in only.** Observability is a real gap the DoD
already gestures at; the rest stays out. This preserves the agnostic-core line while closing the
one gap that has downstream references pointing into the void.
