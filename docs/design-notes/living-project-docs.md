---
type: design-note
title: Living project docs
description: Why CLAUDE.md is assembled from marker blocks rather than shipped as one static template, and why the loop that keeps it true is a skill instead of a hook
---

# Design note: living project docs

`core/claude/CLAUDE.md.tmpl` is installed once at bootstrap. Everything a project then learns about
itself — the command that starts the stack, the suite that needs a seeded database, the trap that
cost an hour — has had nowhere to go. STATE.md is volatile by design, ADRs are for hard-to-reverse
decisions, and specs belong to one feature. The operating knowledge fell through, so every cold
session re-derived it.

Two changes close that: CLAUDE.md gains **marker blocks** that survive a keel upgrade, and
`learn-session` fills them at the boundaries the flow already has.

## Blocks, not one template

A block is `<!-- BEGIN:keel:<id> -->` … `<!-- END:keel:<id> -->`. Two kinds of content live in one:

- **project-learned** (`environment`, `tests`, `conventions`) — written by `learn-session`
- **pack-contributed** (`stack-conventions`, and whatever later packs add) — re-rendered by the
  pack's `install.sh` on every run

`lib/inject-section.mjs` is the only writer at install time. `set` upserts a block; `carry-over`
copies every block from an old file into a fresh one. `bootstrap.sh` snapshots CLAUDE.md before a
`--force` refresh and carries the blocks back afterwards, so a keel upgrade rewrites the body
without erasing what the project knows. Packs run after that step, which makes a pack's own
rendering win over the carried copy — the one direction where "keel is newer" is the right answer.

Why blocks contributed by packs rather than a bigger template: which sections a project should
carry follows from its stack. A project with no database has no use for a database section; a TS
project wants its convention lenses named. `bootstrap.sh` already detects stack signals and
dispatches packs, so the pack that installs the skills also renders the section that points at
them. The alternative — one template with every possible section, most of them empty — is the
monolith this note exists to avoid.

Core seeds exactly one block: `## Environment`. It is the category every project has and no
project had anywhere to record.

## Where a learned fact lands

`learn-session` sorts by **when the fact is needed**, not by what it is about:

| Category | Target | Why |
|---|---|---|
| environment, tests, conventions | CLAUDE.md block | needed before the first edit of every session |
| gotchas | `docs/gotchas.md` (OKF concept) | looked up on contact, not every turn |
| pointers | frontmatter on the target doc | the `okf-index` hook already injects the concept map |

CLAUDE.md is loaded in full on every turn; `docs/` is retrieved on demand. Putting the whole harvest
in CLAUDE.md would trade a stale file for a bloated one. The pointer row is the case where keel
already had the mechanism: a link list would duplicate what `type:`/`description:` frontmatter plus
the SessionStart index does for free.

## Why a skill and not a hook

The obvious shape was a `SessionEnd` hook that distills the transcript. It cannot work. Hooks are
deterministic scripts; deciding that "the seed script must run before the integration suite" is
durable while "we tried three regexes" is noise is a judgment, not a pattern match. `SessionEnd`
receives a transcript path and no way to read meaning from it. This is the same finding as the
slop-guard's (`PostToolUse` cannot block because the tool already ran): the mechanism has to match
what the lever can actually do.

So the distillation is a skill, and the wiring is at the two boundaries the flow already crosses:
`handoff` in PAUSE mode (which is already asking what to keep, and now separates volatile from
durable instead of pushing both into STATE) and `finishing-a-development-branch` (Step 7, skipped
when the work is discarded). No new mechanism, no recurring hook, nothing to schedule.

The skill proposes and waits. Writing into the file that governs every future session, unattended,
would make a wrong inference permanent and invisible.

## Deliberately not done

- **No auto-write.** Approval is the only check on a false lesson entering the always-loaded file.
- **No `SessionEnd` hook, not even as a reminder.** A nudge that fires as the session ends is read
  by nobody, and the next session's version arrives a session late.
- **No block for every category up front.** `tests` and `conventions` blocks are created when there
  is something true to put in them. Empty scaffolding in a fresh project is the failure recorded in
  [Over-constraint audit](over-constraint-audit.md).
- **The injector is not installed into projects.** It is a bootstrap/pack-time tool. In-project block
  edits are ordinary markdown edits by the skill, so nothing new ships into `.specify/`.

Related: [Context engineering audit](context-engineering-audit.md) (a living CLAUDE.md is the
turn-one context contract), [Over-constraint audit](over-constraint-audit.md), [Knowledge packs
roadmap](knowledge-packs-roadmap.md), [OKF adoption](okf-adoption.md).
