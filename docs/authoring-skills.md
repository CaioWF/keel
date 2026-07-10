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

Heavy reference (100+ lines), reusable prompts, or templates go in sibling files next to
`SKILL.md` (e.g. `subagent-driven-development/implementer-prompt.md`). Only `SKILL.md` needs
frontmatter — `audit-structure` skips companions. Keep principles and short patterns inline.

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
