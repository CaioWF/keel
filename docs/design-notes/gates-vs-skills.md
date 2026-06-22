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
| Doc structure | skills have frontmatter, every `specs/NNNN-*` has `spec.md`, no broken links, mermaid parses → `audit-structure` + `validate-mermaid` gates | is the doc *clear/correct*? → review |
| Formatting | prettier / lint → pure gate | — (never a skill) |
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
