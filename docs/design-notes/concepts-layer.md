---
type: design-note
title: Concept layer
description: How the concept layer standardizes engineering principles (Clean Architecture, SOLID, etc.) agnostically across languages using skills, constitution rules, and structure templates
---

# Design note: the language-agnostic concept layer (the container)

The concept layer is the **skill/agnostic** half of `gates-vs-skills.md` applied to engineering
principles (Clean Architecture, SOLID, and so on). It standardizes **what** to build and the
**format**; mechanical **enforcement** lives in the per-language pack (the gate half).

## The recipe: a "concept" is a uniform triple

To add a concept to keel, fill up to four slots — only the first is required:

1. **Guide (required)** — a companion of the `architecture` skill:
   `core/claude/skills/architecture/references/<concept>.md`. Language-agnostic: the principle,
   when to apply it, neutral examples, how it maps to structure. This is the "how to think".
   The companions live in `references/` because five independent concepts are a domain fan-out —
   you read the one that applies (see [skill anatomy audit](skill-anatomy-audit.md)).
2. **Constitution rule (optional)** — if the concept has a **non-negotiable** the agent can
   verify, add one imperative line under `## Architecture Principles` in `constitution.md.tmpl`.
   Keep it short. The depth belongs in the guide, not here.
3. **Structure note (optional)** — if the concept shapes folder/module layout, describe the
   format in `architecture-template.md` (agnostic; each language realizes it in its own idiom).
4. **Enforcement pack (optional, per language)** — if the rule can be imposed mechanically, the
   config goes in a `packs/<lang>-<concept>/` pack (for example `ts-clean-arch` with
   dependency-cruiser), wired into `run-gates.sh`. NEVER in the agnostic core.

## Why this shape

- **Umbrella skill + companions** (not N loose skills): one entry point in the SDD chain,
  concepts plug in as companions, and it audits cleanly (only `SKILL.md` needs frontmatter).
- **Constitution carries only the hard parts**: it is injected at SessionStart — keep it lean.
  The guide carries the rest.
- **Structure = format, not code**: layer code is language-specific (= pack).
- **Guide ↔ pack**: the guide is the source; the pack is the guide expressed in one language's
  linter. Guide without pack = advisory (acceptable); pack without guide = a rule with no
  rationale (avoid).

## Current curated set

| Concept | Guide | Constitution rule | Structure note | Pack |
|---|---|---|---|---|
| Clean Architecture | `references/clean-architecture.md` | dependency rule | layers | `ts-clean-arch` (deferred) |
| SOLID | `references/solid.md` | — | — | (per-language lint, later) |
| Testing strategy | `references/testing-strategy.md` (points to `test-driven-development`) | test behavior | — | test gate already exists |
| Tactical DDD | `references/ddd-tactical.md` | aggregate boundary | — | — |
| Minimalism | `references/minimalism.md` | minimum viable + carve-out | — | (advisory; no pack) |

Growing = one more row in the table plus the recipe's slots. No code changes.

## Related

- [Gate vs skill](gates-vs-skills.md) — the gate-vs-skill rule this layer applies on the skill side
- [Skill anatomy audit](skill-anatomy-audit.md) — why the guides live in `references/`
- [Agnostic concept layer](../plans/2026-06-22-agnostic-concept-layer.md) — the plan that implements this design note
