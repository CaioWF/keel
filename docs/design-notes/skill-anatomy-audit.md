---
type: design-note
title: Skill anatomy audit
description: Audit of every keel skill against the official Agent Skills anatomy, the measured thresholds that decided the references/ convention, and the domain fan-out rule that replaced a made-up line count
---

# Design note: skill anatomy audit

An audit of all 31 core skills and 9 pack skills against the canonical Agent Skills anatomy
(`SKILL.md` + `references/` + `scripts/` + `eval/`). The question it set out to answer was
whether keel should adopt `references/` as a subdirectory convention. The measurement changed
the question.

## What the docs actually specify

The [Agent Skills authoring
guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
carries four numbers. Measured against keel:

| Guidance | Limit | keel |
|---|---|---|
| `SKILL.md` body | under 500 lines | largest is 289 (`subagent-driven-development`) — all pass |
| `description` | max 1024 chars | all pass |
| `name` | max 64 chars, `[a-z0-9-]` only | all pass |
| reference file over 100 lines | needs a table of contents | 3 violated, now fixed |
| reference links | one level deep from `SKILL.md` | no nesting found |

**The size argument for `references/` does not survive contact with the number.** The original
proposal in this repo's TODO used a 150-line threshold. That number was invented. No keel skill
is within 200 lines of the real one, so "split it because it is big" was never the reason to
split anything here.

## The rule that replaced it

The docs show *two* shapes as equally valid, and the distinction between them is not size:

- **Pattern 1** — flat siblings (`pdf/SKILL.md`, `FORMS.md`, `reference.md`, `examples.md`).
- **Pattern 2** — a `reference/` subdirectory, introduced explicitly "for Skills with multiple
  domains… to avoid loading irrelevant context."

So the criterion is **domain fan-out**: does the reader pick one of N companions per task, or
read the one companion that exists? keel's rule, derived from that:

> Two or more companions covering independent topics go in `references/`. A single companion
> stays a flat sibling.

Applied:

| Skill | Companions | Shape |
|---|---|---|
| `architecture` | 5 independent concepts | **moved to `references/`** — the textbook Pattern 2 case, and the one that was flat |
| `subagent-driven-development` | 3 references + 2 prompt templates | already `references/`, unchanged |
| `test-driven-development` | 1 (`testing-anti-patterns.md`) | flat sibling, unchanged |
| `finishing-a-development-branch` | 1 (`definition-of-done.md`) | flat sibling, unchanged |
| `systematic-debugging`, `dispatching-parallel-agents` | 1 each (new) | flat siblings |

`architecture` moving into `references/` supersedes slot 1 of the recipe in
[concepts-layer.md](concepts-layer.md), which prescribed a flat companion.

## What the audit found beyond shape

**A real defect in the multi-client views.** `lib/emit-views.mjs` listed companions with a
non-recursive `readdirSync` filtered to `isFile()`, so `references/` subdirectories were
silently dropped. Every non-Claude view (Codex, and any future skill-dir client) shipped
`subagent-driven-development` with a body linking three files that were never emitted — broken
since the pilot landed. The walk is now recursive, and a test pins it. This had to be fixed
*before* widening the convention, or the migration would have multiplied the breakage.

**The gate was blind to keel's own skills.** `isSkill()` matched only `/.claude/skills/`, which
is the *installed* layout. keel's source lives in `core/claude/skills/`, so `audit-structure`
had never validated a single one of the skills keel ships — only the ones it installs into
other projects. Now matched on `/skills/`, so the corpus is audited where it is authored.

**Vendored narrative in the always-loaded body.** Two skills carried a combined ~54 lines of
another project's session anecdotes and self-reported metrics ("95% vs 40%", "Time saved",
a dated 2025-10-03 debugging session). None of it changes what the agent does. It moved to
`field-notes.md` companions rather than being deleted — the material explains why the technique
was written down, which is worth keeping, just not worth spending context on every dispatch.
Related: a heading mangled by an upstream find-replace (`## your human partner's Signals You're
Doing It Wrong`) is fixed, and the borrowed second-person possessive is normalized to keel's
own voice across five skills.

## What the gate now enforces, and the line between error and warning

`audit-structure` splits the new checks by *what breaks if you ignore them*:

- **Errors** (`name` charset, `name` length, `description` length) are the platform's own
  validation. A skill that violates these does not load at all, so the gate refusing to pass is
  the same answer the runtime would give, only earlier.
- **Warnings** (body over 500 lines, long companion without a ToC) are authoring guidance. They
  print and do not change the exit code.

Hard-failing the guidance was rejected. These gates ship into other people's projects via
bootstrap, and a project whose own skill runs to 600 useful lines should not have its build
broken by keel's opinion about context budgets. This is the [over-constraint
audit](over-constraint-audit.md) conclusion applied to a new rule: enforce what is mechanically
true, advise what is a judgment call.

`*-prompt.md` files are exempt from the ToC rule. They are copied verbatim into a dispatched
brief, so a table of contents would leak into the prompt itself. The rule is about files an
agent may read partially; a prompt template is never read that way.

## What was deliberately not done

**`scripts/` and `eval/` per skill.** keel already has both, centrally: deterministic logic
lives in `core/gates/*.mjs` and skill tests in `tests/test-skills-*.sh`. Co-locating them per
skill would fragment the gate runner and the test runner to match a directory picture, with no
behavior improvement. The anatomy is a description of what a skill *may* contain, not a
checklist every skill owes.

The one real gap this leaves is worth naming: the docs describe evaluations as behavioral
scenarios ("at least three", written *before* the skill) and keel's `tests/test-skills-*.sh` are
grep assertions over prose. They verify a skill still *says* a thing, not that an agent given
the skill *does* it. That is a genuine difference in kind, and closing it needs an eval harness,
not a directory.

**Skill naming.** The docs recommend gerund form and warn against inconsistent patterns within a
collection. keel is mixed: `brainstorming` and `using-git-worktrees` alongside `spec-writer` and
`evaluator`. Renaming is breaking — the phase machine, the chain documentation, and the tests
all key on these names — and the payoff is cosmetic. Flagged, not changed.

**The remaining companion over 100 lines.** `task-reviewer-prompt.md` (197 lines) is exempt by
the prompt-template rule above, not by oversight.

## Related

- [Gate vs skill](gates-vs-skills.md) — which half of a concern is mechanical
- [Concept layer](concepts-layer.md) — the recipe whose slot 1 this note updates
- [Over-constraint audit](over-constraint-audit.md) — why guidance warns instead of blocking
- [Context engineering audit](context-engineering-audit.md) — progressive disclosure as a context-budget tool
- [Authoring keel skills](../authoring-skills.md) — the rule as an authoring instruction
