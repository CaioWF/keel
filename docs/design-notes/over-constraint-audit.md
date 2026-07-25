---
type: design-note
title: Over-constraint audit
description: Where keel's own scaffolding capped the ceiling instead of raising the floor — the measured trivial-change contradiction, the declared path that fixes it, and the de-duplication that followed
---

# Design note: over-constraint audit (2026-07-25)

Distinct from the [context engineering audit](context-engineering-audit.md), which asked whether
each step receives the right context. This one asks the harsher question: **where does keel's
scaffolding cost capability?** Not "is this rule redundant" but "does this rule prevent a better
outcome than the rule".

The prompt for it is the eighth rule in Anthropic's context-engineering guidance: replace
prescriptive rules with principle-based guidance, because a current model applies judgment without
them. Read literally, every `never` in this repo claims that judgment would fail in that spot. keel
carries **235 imperative clauses** (`never`, `MUST`, `do not`, `always`, `REQUIRED`) across `core/`,
concentrated in `subagent-driven-development` (26), `CLAUDE.md.tmpl` (18 before this pass), and
`task-reviewer-prompt.md` (14). Each one is a bet. Most are good bets. This note is about the ones
that were not.

## The finding: a typo cost six artifacts and two approvals

Three parts of keel answered the same question three different ways:

| Source | Policy on a trivial change |
|---|---|
| `brainstorming/SKILL.md` (HARD-GATE) | "applies to EVERY project regardless of perceived simplicity"; "a todo list, a single-function utility, a config change — all of them" |
| `CLAUDE.md.tmpl` | "`brainstorming` is the entry point for any **non-trivial** feature, refactor, or bug fix" — implying trivial work is exempt |
| `doubt-driven-development/SKILL.md:24` | explicit carve-out: "Do NOT use for trivial, reversible, or mechanical changes (renames, formatting, one-line config)" |

Worse than the contradiction: the exemption `CLAUDE.md` implied **could not be taken**. The
phase-gate keys on approved artifacts, not on the size of a change, so skipping `brainstorming` left
every code edit blocked anyway. Measured in a bootstrapped sandbox, fixing a one-word typo in
`src/greet.ts`:

```
[keel:phase-gate] Blocked: feature 'none' has no approved spec.md+plan.md
phase-gate exit=2
```

keel's real answer for a typo was therefore: run `brainstorm → prd → spec → clarify → plan → tasks`
(six artifacts, two human approvals), or bypass the gate — which `CLAUDE.md` forbade in the same
paragraph that described it. In practice a human bypasses, undocumented, and the discipline quietly
teaches that its rules are negotiable when inconvenient. That is worse than either honest answer.

It also contradicted the operator's own standing policy, which exempts typos, mechanical renames,
trivial config, and one-file two-line changes as long as the skip is announced.

## The fix: a declared door, not a bypass

The phase-gate now recognizes a trivial-change path, shaped so it cannot quietly become the default
route:

- **Declared.** The reason goes in `.specify/trivial`, one line. No marker, no door.
- **Announced.** The reason is echoed on every edit it permits, the hook returns an explicit
  `permissionDecision: "allow"` carrying it, and `CLAUDE.md` requires the skip to be stated in the
  response.
- **Bounded by size, not by adjective.** Edits over 10 lines (`KEEL_TRIVIAL_MAX_LINES`) are refused
  with a message naming the limit. "Trivial" is not something the agent gets to feel its way to.
- **Expiring.** The marker goes stale after 30 minutes (`KEEL_TRIVIAL_TTL_MIN`), so a forgotten one
  does not become policy.
- **Never committed.** `bootstrap` adds it to `.gitignore`: a checkout resets mtime, so a committed
  marker would be permanently fresh — an open gate in every clone.
- **Discoverable.** The block message names the path, because an escape hatch nobody knows about is
  the same as no escape hatch.

`brainstorming`'s HARD-GATE keeps its teeth — the anti-rationalization section is the point — and
gains the carve-out in the terms `doubt-driven-development` already used: a change is trivial when
its shape is decided before you start and nothing about it is a judgment call. The moment it
acquires a decision, the gate applies again.

## The de-duplication that followed

The [context engineering audit](context-engineering-audit.md) left three proposals, all instances of
one disease. Applied here:

- **The implementer brief stopped restating `CLAUDE.md`.** A dispatched subagent inherits the
  project's `CLAUDE.md`, so the Iron Law, the laziness ladder, YAGNI, the No-Commit Rule, and code
  organization all arrived twice in slightly different words. 168 lines → 99, and what survives is
  task-specific. The "ask questions" instruction became what the protocol always meant: report
  `NEEDS_CONTEXT`, since a dispatched subagent has no human to ask.
- **`CLAUDE.md.tmpl` went from 101 to 88 lines while gaining the trivial-change paragraph.**
  Operational detail (slop-guard knobs, contract mechanics, the OKF tooling map) moved to the hook
  headers and design notes that own it; what stays is the rule plus a pointer.
- **Model routing collapsed to one source.** `subagent-driven-development`'s `## Model Selection`
  decides; `implement-feature` and `fix-runner` point at it instead of paraphrasing it.

## What was left alone, deliberately

- **The TDD Iron Law.** A real project choice that a model does not default to. Kept, stated once.
- **The No-Commit Rule.** It protects the human's approval boundary, and the cost of being wrong is
  asymmetric.
- **One task at a time in `implement-feature`.** A plausible ceiling on a model that could hold two
  adjacent tasks at once, but the per-task evaluator loop depends on it. Flagged, not changed.
- **The 235 clauses in aggregate.** Rule 8 argues for auditing them one at a time against "would
  judgment fail here?". This note did that where there was evidence; doing it wholesale on suspicion
  would trade one unexamined position for another.

## No mechanism, on purpose

No `over-constraint-audit` skill, no gate, no lens. Building permanent scaffolding to detect excess
scaffolding is the failure mode this note is about, and it is the same conclusion the context audit
reached about per-skill context contracts. Re-running this means asking for it, with the recipe
above: count the imperative clauses, find the ones stated in more than one place, and test whether
the cheapest legitimate change can actually get through.

See also: [context engineering audit](context-engineering-audit.md),
[gates vs skills](gates-vs-skills.md).
