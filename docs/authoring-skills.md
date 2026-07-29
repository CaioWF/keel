---
type: reference
title: Authoring keel skills
description: Guide for writing skills in keel following TDD methodology, including when to create a skill, SKILL.md structure, and how to wire new skills into the keel framework
---

# Authoring keel skills

Reference for adding/editing skills in `core/claude/skills/`. Distilled and adapted from
superpowers `writing-skills` (the keel vendored its discipline skills under Path A; this is
the meta-guide for writing more). Pairs with `docs/design-notes/gates-vs-skills.md` (skill vs
gate) and `docs/design-notes/concepts-layer.md` (the concept-container recipe).

## Writing a skill IS TDD applied to process docs

You write the test (a pressure scenario), watch it fail (baseline behavior without the skill),
write the skill, watch it pass (the agent complies), refactor (close loopholes). Follow the same
RED→GREEN→REFACTOR as `core/claude/skills/test-driven-development`.

**Core principle:** if you didn't watch an agent fail *without* the skill, you don't know the
skill teaches the right thing.

| TDD | Skill creation |
|---|---|
| Test case | Pressure scenario (a subagent told to do the task) |
| Production code | `SKILL.md` |
| RED | Agent violates the rule without the skill (baseline) |
| GREEN | Agent complies with the skill present |
| Refactor | Close the rationalizations it finds, re-verify |

## When to create a skill (vs a gate, vs nothing)

Create when: the technique wasn't obvious, you'd reference it again, it applies broadly (not
project-specific), it's a **judgment call**.

Do NOT create when:
- It's mechanically enforceable → make it a **gate** (`core/gates/`), not prose. See gates-vs-skills.
- It's project-specific → put it in the project's `CLAUDE.md`/constitution, not core.
- It's a one-off narrative ("how I solved X once").

A skill is a reusable technique/pattern/reference — not a story.

## SKILL.md structure

Frontmatter — exactly two fields the keel audits (`audit-structure` requires them):
- `name`: letters/numbers/hyphens only, matches the directory name.
- `description`: **third-person, describes ONLY when to use** — start with "Use when…", list
  symptoms/contexts. NEVER summarize the workflow (the agent reads the body for that; a
  process-summary description makes it skip the body). Keep it tight.

Body, roughly: `## Overview` (what + core principle in 1-2 lines) → `## When to use` (symptoms,
and when NOT to) → the technique (steps/patterns) → `## Red Flags` / `## Common Mistakes` (the
rationalizations that break it). Imperative voice, concrete examples.

## Companion files

Heavy reference, reusable prompts, or templates go in companion files beside `SKILL.md`. Only
`SKILL.md` needs frontmatter — `audit-structure` skips companions. Keep principles and short
patterns inline.

**Flat sibling or `references/` subdir — decide by domain fan-out, not by size:**

> Two or more companions covering independent topics go in `references/`. A single companion
> stays a flat sibling.

The test is whether the reader picks one of N per task (`architecture/references/solid.md` vs
`ddd-tactical.md` — you read the one that applies) or reads the only companion there is
(`test-driven-development/testing-anti-patterns.md`). Both shapes are conformant; the subdir
exists to keep the other domains out of context, so it earns nothing when there is no other
domain. Reasoning in [skill anatomy audit](design-notes/skill-anatomy-audit.md).

**Limits `audit-structure` checks** (from the [Agent Skills authoring
guide](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)):

| Rule | Level | Why |
|---|---|---|
| `name` max 64 chars, `[a-z0-9-]` only | error | platform validation — the skill will not load |
| `description` max 1024 chars | error | same |
| `SKILL.md` body under 500 lines | warning | authoring guidance, not a hard limit |
| companion over 100 lines has a `## Contents` list | warning | a partial read still shows the full scope |

`*-prompt.md` is exempt from the ToC rule: those files are copied verbatim into a dispatched
brief, so a table of contents would leak into the prompt.

**Keep companion links one level deep from `SKILL.md`.** A companion that points at another
companion invites partial reads of both — link every file from the body instead.

## What keel does not adopt from the canonical anatomy

The reference anatomy is `SKILL.md` + `references/` + `scripts/` + `eval/`. keel takes the first
two and keeps the other two central: deterministic logic belongs in `core/gates/*.mjs` (see
[gate vs skill](design-notes/gates-vs-skills.md)) and skill tests in `tests/test-skills-*.sh`.
Do not add per-skill `scripts/` or `eval/` directories without a reason that survives the
gate-vs-skill question.

## Pressure-test before shipping

Skills are behavior-shaping code, not docs. Before adding one:
1. Run the bare task on a subagent → record the exact rationalizations/violations (RED).
2. Write the skill addressing *those specific* violations (minimal).
3. Re-run → confirm compliance (GREEN).
4. Find the next loophole → plug → re-verify (REFACTOR).

Don't reword carefully-tuned behavior content (Red Flags tables, rationalization lists) without
evidence it improves outcomes.

## Wiring a new skill into the keel

- Place it under `core/claude/skills/<name>/SKILL.md` → bootstrap copies it + emit-views renders
  client views automatically.
- If it belongs in the SDD chain, add it to the chain line in `core/claude/CLAUDE.md.tmpl`.
- Add a test asserting it exists + has `name` frontmatter (see `tests/test-skills-*.sh`); for
  vendored skills, assert no `superpowers:` cross-refs remain (Path A).
- If it's an architecture *concept*, don't make a top-level skill — follow the concept-container
  recipe (`docs/design-notes/concepts-layer.md`): add a companion under the `architecture` skill.

## Related

- [Keel design](specs/2026-06-17-keel-design.md) — the design spec for keel that defines the skill architecture and framework
