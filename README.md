# Keel

A zero-dependency **spec-driven development (SDD)** scaffolder. Run one script in any
project and it installs the full SDD flow — document templates, discipline skills, active
hooks, and quality gates — so an AI coding agent (Claude Code first; Codex, Cursor, Copilot,
Gemini, Windsurf as generated views) builds features with spec → plan → gates → review
discipline instead of jumping straight to code.

No runtime dependencies. The hooks and gates are plain Node `.mjs` using only `node:`
builtins — no Python, no third-party plugin, nothing that auto-updates underneath you.

## Why

Agents are happy to write code before there's a spec, skip the plan, and commit without
review. Keel makes the discipline **mechanical**: a phase gate refuses to edit code until a
spec and plan are both approved, a pre-commit gate runs the quality checks before every
commit, and a doc gate enforces that every acceptance criterion is traced to a task. The
agent works around the gates by getting approval — never by disabling them.

## Install

From inside the target project:

```bash
bash /path/to/keel/bootstrap.sh
```

This lands (idempotently — existing files are kept unless `--force`):

- `.specify/` — templates (spec, plan, tasks, constitution, architecture), quality gates
- `.claude/hooks/` — SessionStart context loader, phase sensor, phase gate, pre-commit gate
- `.claude/skills/` — the SDD chain + discipline skills
- `docs/` — `STATE.md` (working memory) + `architecture/adr/` (decision records)
- `CLAUDE.md` (+ `AGENTS.md`)

Generate views for other agents too:

```bash
bash bootstrap.sh --agent=codex,cursor   # or --all
```

Requires Node (for the hooks/gates). No other dependency.

## The SDD flow

```
brainstorming → prd-writer → spec-writer → clarify → plan-writer → tasks-writer
  → analyze → implement-feature → implement-and-evaluate → review-and-simplify
  → finishing-a-development-branch
```

Code edits are blocked by the **phase gate** until the active feature's `spec.md` and
`plan.md` both carry `status: approved`. Implementation follows TDD (test behavior, not
implementation). `review-and-simplify` runs `code-review` + `security-review` in parallel
then a behavior-preserving `simplify` pass before any commit is proposed.

## Quality gates

`.specify/gates/run-gates.sh` runs on every commit (via the pre-commit hook) and includes
zero-dep doc gates:

- **audit-structure** — skill frontmatter, every `specs/NNN-*/` has a `spec.md`, no broken links
- **eval-spec-fidelity** — every `AC-N` in the spec is covered by a task (traceability), counts `SPEC_DEVIATION` markers
- **validate-mermaid** — mermaid blocks parse

plus the project's own `lint` / `test` / `build` when present (npm or make, auto-detected).

## Design

Two notes capture the architecture:

- [`docs/design-notes/gates-vs-skills.md`](docs/design-notes/gates-vs-skills.md) — the split:
  mechanical concerns → **gates** (deterministic, hard-blocking, zero tokens); judgment calls →
  **skills** (read-only lenses, discipline).
- [`docs/design-notes/concepts-layer.md`](docs/design-notes/concepts-layer.md) — the
  language-agnostic concept layer (Clean Architecture, SOLID, testing strategy, DDD tactical)
  lives in the `architecture` skill + constitution; per-language *enforcement* lives in optional
  packs.

[`docs/authoring-skills.md`](docs/authoring-skills.md) — how to add a skill (skill-as-TDD).

## Status

Validated end-to-end on a real project. Test suite is plain shell (`bash tests/run.sh`),
no framework.

## License

MIT — see [LICENSE](LICENSE).
