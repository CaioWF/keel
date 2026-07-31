---
type: design-note
title: Gate vs skill
description: Decision rule for splitting review concerns: mechanical/deterministic rules belong in gates, judgment-based concerns in skills
---

# Design note: gate vs skill — where a review concern belongs

**Decision rule:** split by determinism.

- **Mechanical / deterministic** (pass/fail, no judgment) → **gate**. Cheap,
  fast, hard-blocking, zero tokens. Runs via `core/gates/run-gates.sh`
  (auto-detects `npm run lint/test/build` or `make lint/test`); the
  `precommit-gate.mjs` hook blocks the commit when a gate fails.
- **Requires judgment** an analyzer can't encode → **skill**. A read-only lens
  inside `review-and-simplify` (`code-review`, `security-review`) or a
  discipline skill (`test-driven-development`).

Prefer a gate whenever the rule can be expressed deterministically — mechanical
enforcement is more reliable and cheaper than asking the agent every time.
Skills are for what cannot be mechanized.

## Most concerns have both halves

| Concern | Gate half (mechanical) | Skill half (judgment) |
|---|---|---|
| Naming | camelCase/snake, no leading `_`, length → a lint rule | is the name descriptive? avoids `data`/`handler`/`Manager` for *this* thing? → `code-review` / `simplify` |
| Tests | pass? coverage %? test file exists? | test BEHAVIOR not mocks/implementation? edge cases? → `test-driven-development` + `code-review` |
| Traceability | each `AC-N` covered by a task? `SPEC_DEVIATION` count → `eval-spec-fidelity` gate | is the AC the *right* one? does the impl truly satisfy it? → `code-review` |
| Verification | each `AC-N` has a `## AC-N` section in `contract.md`, none left over from a dropped AC (warn-only) → `eval-spec-fidelity` gate | does the declared proof actually prove the criterion? did it pass? → `evaluator` (see [verification contract](verification-contract.md)) |
| Proportionality | is this edit actually small, is a reason declared, has the marker expired? → `phase-gate` trivial path | is this change genuinely free of judgment calls? → the author, who must announce the skip (see [over-constraint audit](over-constraint-audit.md)) |
| Doc structure | skills have frontmatter, every `specs/NNNN-*` has `spec.md`, no broken links, mermaid parses → `audit-structure` + `validate-mermaid` gates | is the doc *clear/correct*? → review |
| Skill anatomy | `name` charset/length, `description` length (errors); body over 500 lines, long companion with no ToC (warnings) → `audit-structure` | does this companion earn its own file, and does the split follow domain fan-out? → the author (see [skill anatomy audit](skill-anatomy-audit.md)) |
| Project memory | marker blocks upserted and carried across a `--force` refresh, pack sections re-rendered → `lib/inject-section.mjs` at bootstrap/pack time | which learned fact is durable, and does it belong in the always-loaded file or in `docs/`? → `learn-session` (see [living project docs](living-project-docs.md)) |
| Recorded reasoning | payload path changed with no `docs/{design-notes,plans,specs}` change and no declared trivial door → `ci/rationale-check.mjs`, in CI | is the note the *right* reasoning, and is it true? → the author and review (see [CI and server-side gates](ci-server-side-gates.md)) |
| Formatting | prettier / lint → pure gate | — (never a skill) |
| Prose | AI-writing tells (`not just X, but Y`, throat-clearing, borrowed vocabulary) → `slop-guard` hook, advisory (see [prose slop-guard](prose-slop-guard.md)) | is the doc actually clear and true? → `code-review` / `simplify` |
| Types | `tsc` → gate | — |
| Security | secret-scan regex, `npm audit` → can become a gate | allow-list authz, injection, SSRF → `security-review` |

A concern with both halves: encode the hard half as lint/test (gate), keep the
meaning half as a lens (skill).

## Agnostic-core implication

The stack-agnostic core **cannot ship concrete lint/naming rules** (an
`.eslintrc`, a formatter config — these are stack-specific). The core ships the
**runner** (`run-gates.sh`) — the hook point — not the rules. The concrete
naming/format/lint config comes from:

- the **target project** (its own `.eslintrc`, etc.), or
- the **`ts-clean-arch` pack** (Plan 2), which provides the opinionated
  naming/format/lint config ready to go.

So "naming-as-lint" is a **gate** whose content the project/pack fills in;
"naming-as-meaning" lives in the **skill** layer (`code-review` / `simplify`).
Both layers already exist in core; only the concrete gate config is deferred to
the pack/project.

**Exception — stack-agnostic gates that core CAN ship with content.** Some
mechanical rules need no stack-specific config because they operate on the SDD
artifacts themselves, not on source: doc structure (`audit-structure`), spec→task
traceability (`eval-spec-fidelity`), and mermaid syntax (`validate-mermaid`).
Core ships these as ready-to-run `.mjs` gates in `core/gates/`, wired into
`run-gates.sh` to always run. Stack-specific *source* gates (lint/format/types)
stay deferred to the project/pack; agnostic *artifact* gates ship complete.

## Related

- [Concept layer](concepts-layer.md) — applies the gate-vs-skill rule at the level of engineering concepts
