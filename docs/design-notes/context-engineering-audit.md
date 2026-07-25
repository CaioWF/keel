---
type: design-note
title: Context engineering audit
description: Per-handoff audit of what each chain skill reads, what it is missing, and where keel repeats itself — plus the conclusion that the fix is mostly deletion
---

# Design note: context engineering audit (2026-07-25)

The question: does each step of the chain receive the **right and sufficient** context — not so
little that it re-explores or guesses, not so much that it dilutes and costs?

Method: read every chain skill's declared inputs, the two SessionStart injectors, and the subagent
brief; compare what each declares reading against what it demonstrably needs to do its job. Evidence
is cited as `file:line`. Findings are grouped as **missing** (should receive and does not) and
**redundant** (receives, or is told, the same thing more than once).

## The checklist

Eight rules from Anthropic's "The new rules of context engineering for Claude 5-generation models",
quoted from the source:

1. **System prompt = product context.** "A system prompt is heavily tied to the product context. It
   tells Claude what product it's operating in and what it's doing."
2. **Design tools, don't demonstrate them.** "Instead of using examples, think more about the design
   of your tools, scripts and files." Examples constrain the model to the demonstrated pattern.
3. **Progressive disclosure through skills.** "We moved verification and code review into their own
   skills that Claude Code could selectively call."
4. **Eliminate redundancy and conflict.** The failure mode named in the article is "several
   conflicting messages in a single request like 'leave documentation as appropriate,' or 'DO NOT add
   comments.'" The model then "must think more carefully" before deciding, spending reasoning tokens
   on nothing.
5. **Light `CLAUDE.md`.** "Keep your CLAUDE.md lightweight and briefly describe what your repo is
   for, but spend most of the tokens on gotchas inside of the codebase."
6. **Automatic memory** over manual entries: "Claude now automatically saves memories that are
   relevant to the work and to you."
7. **References as code.** "A spec may also be a detailed test suite, or a function in a different
   codebase that Claude might port" — code carries "clear, high-fidelity instructions".
8. **Judgment over rules.** The article's own illustration: replace "Never write multi-paragraph
   docstrings" with "Write code that reads like the surrounding code: match its comment density,
   naming, and idiom."

## What each handoff declares reading

| Step | Declares reading | Verdict |
|---|---|---|
| `brainstorming` | "check files, docs, recent commits" (`SKILL.md:26`) | vague, and blind to what SessionStart already injected |
| `prd-writer` | `product.md` (`SKILL.md:15`), `specs/*` for the ordinal | good — the product layer is referenced, not copied |
| `spec-writer` | `.specify/state`, the template (`SKILL.md:15-16`) | **never reads `prd.md`** |
| `clarify` | `spec.md` + `prd.md` + `brainstorm.md`, then the repo before asking (`SKILL.md:20-23`) | best contract in the chain |
| `plan-writer` | `spec.md`, `docs/codebase-map.md`, `impl-conventions.txt` (`SKILL.md:16-18`) | **never reads `prd.md`** → the seams die there |
| `tasks-writer` | `plan.md`, spec ACs for the contract (`SKILL.md:16`, step 7) | adequate |
| `analyze` | `spec.md`, `plan.md`, `tasks.md`, `contract.md`, `codebase-map.md` | adequate |
| `implement-feature` | `tasks.md` + slices of `spec.md`/`plan.md`, `impl-conventions.txt` (`SKILL.md:16-17`) | **no `contract.md`** — cannot see how its work gets verified |
| implementer subagent | its brief file + a free-form `## Context` block (`implementer-prompt.md:15-20`) | least context of any actor, most consequential work |
| `evaluator` | `contract.md`, `spec.md` | adequate (rebuilt today) |
| `fix-runner` | gate output (`SKILL.md:15`) | adequate — narrow on purpose |
| `handoff` | `STATE.md` + the active `spec.md`/`tasks.md`, and says STATE is already injected (`SKILL.md:41`) | model citizen: knows what it already has |

## Missing context

1. **`spec-writer` does not read the PRD.** Steps 1-4 resolve the active feature, copy the template,
   fill sections. The document it exists to specify is never opened. This works today only because
   the PRD usually sits in the session's history — the exact dependency a fresh-context dispatch
   breaks.
2. **`plan-writer` does not read the PRD, so the feature seams die at the PRD.** `prd-writer`
   collects `Consumes` / `Exposes` / `Dependencies` and states that "the technical contract belongs
   in `plan.md`" (`prd-writer/SKILL.md:24-25`). `plan-writer` never opens `prd.md`. Two features
   shipped days apart (seams in `bd8922b`, the plan flow in core) with no link between them.
3. **`implement-feature` does not read `contract.md`.** Step 3 lists spec and plan slices but not the
   verification contract, so the implementer cannot see the `command` and `observable` that will
   judge its work minutes later. The cheapest alignment available, currently absent.
4. **The implementer brief hands over the least context in the chain.** `implementer-prompt.md`
   passes a brief file plus a free-form `## Context` placeholder. It never points at the spec's
   acceptance criteria, `contract.md`, or the `impl-conventions.txt` lenses. A subagent inherits no
   session history by design, so whatever the brief fails to name is genuinely absent for it.
5. **`brainstorming` re-discovers what it was handed.** "Explore project context — check files,
   docs, recent commits" ignores that `load-constitution.mjs` already injected the product brief,
   the constitution, and `STATE.md`, and that `okf-index.mjs` injected the concept map at zero tool
   calls. The instruction buys tool calls for context already in the window (rules 3, 6).

## Redundancy

6. **The implementer brief restates what `CLAUDE.md` already mandates.** TDD's Iron Law, the
   laziness ladder, YAGNI, test-behavior-not-mocks, the No-Commit Rule, code organization: each
   appears in `CLAUDE.md.tmpl` and again in `implementer-prompt.md:22-116`. Subagents inherit the
   project's `CLAUDE.md`, so every dispatch pays twice, and any wording drift between the two
   becomes something the model has to reconcile (rules 1, 4).
7. **One model-routing rule, four sources.** `subagent-driven-development/SKILL.md:170-201`
   (`## Model Selection`), `implement-feature/SKILL.md:24`, `fix-runner/SKILL.md:22`, and the global
   `routing-minimum-capable-model` skill all state it (rule 4).
8. **`CLAUDE.md.tmpl` is drifting into a policy manual.** Eleven sections and 101 lines, carrying
   `slop-guard` env knobs, `contract.md` mechanics, and the OKF tooling map. Two sections were added
   during this same session, which is the point: every feature wants a paragraph there, and nothing
   ever removes one (rule 5). *Addressed in the [over-constraint audit](over-constraint-audit.md):
   88 lines, detail moved to the hooks and notes that own it.*
9. **`subagent-driven-development` carries two `dot` graphs (~60 of its 290 lines)** that redraw
   flows the surrounding prose already states. It defers three documents to `references/` correctly;
   the graphs and `## Model Selection` are the remaining bulk (rules 3, 4).
10. **"spec+plan must be approved before code" is stated five times** — `CLAUDE.md.tmpl`,
    `spec-writer:24`, `plan-writer:34`, `implement-feature:8`, and the `phase-gate` hook that
    actually enforces it. The hook is the authoritative source; the rest is commentary (rule 4).
11. **The implementer brief tells the subagent to "ask questions"; the protocol says report a
    status.** `implementer-prompt.md:53` ("Ask them now") and `:66` ("If you encounter something
    unexpected or unclear, **ask questions**") sit against `SKILL.md:17`, which tells the controller
    not to pause, and against the four-status vocabulary where `NEEDS_CONTEXT` is exactly the
    channel for a missing fact. A dispatched subagent cannot reach the human at all, so "ask" and
    "report NEEDS_CONTEXT" are the same act described two ways — the mixed-message shape rule 4
    warns about. Say it once, in the protocol's own words.
12. **The prompt templates are the pattern rule 2 moves away from.** `implementer-prompt.md` and
    `task-reviewer-prompt.md` are prescriptive fill-in-the-blank examples of a dispatch, in a
    harness where the dispatch tool's own parameters (description, model, prompt, isolation) already
    express what a dispatch is. Worth revisiting alongside finding 6 rather than separately.

## What already works, and should not be "improved"

- `references/` deferral in `subagent-driven-development` (dispatch mechanics, troubleshooting,
  worked example) — rule 3, done right, and the model for the skill-anatomy work.
- File handoffs: briefs and reports pass as **file paths**, never pasted bulk, with a size gate. The
  42k-char pasted-history incident is what taught this.
- `okf-index` progressive disclosure: a real total, per-type overflow pointers, `KEEL_OKF_BUDGET`.
- `load-constitution` injecting product brief, constitution, and STATE — product and operational
  context in the system prompt, per rule 1.
- `clarify` fact-checking the repo before spending the user's attention.
- `contract.md`'s `proof: tests/auth.spec.ts:42` already satisfies rule 7: the acceptance criterion
  points at a test, so the high-fidelity artifact is the reference, not a prose restatement.
- Checked and clean: the article's own conflict example (documentation guidance versus "DO NOT add
  comments") does not reproduce here. `CLAUDE.md.tmpl:63` (comment WHY not WHAT) and `:67` (plain
  prose) agree with each other and with the `slop-guard` rules.

## Conclusion: the fix is mostly deletion

keel's context problem is not scarcity. Four broken links aside, the chain suffers from the same
instruction arriving from several directions at once. That reframes the mechanism question the TODO
left open (audit vs. a context contract per skill vs. a gate):

- **A `## Context contract` section in every skill is the wrong answer.** It would add roughly two
  hundred lines of scaffolding to a corpus whose main defect is duplication — the over-constraint
  trap, arriving disguised as the cure.
- **Each broken link is one clause** inside a step that already exists. Fix them inline and pin each
  with a test assert so they cannot rot.
- **No new gate.** An audit that has to be re-run by hand is a document, not a gate; and a gate
  demanding declared inputs would ossify the very prose this note wants shorter.

Fixed in the same pass as this note: the four missing links (findings 1-5), plus `spec-writer`
telling the model to number requirements `RF1` while the template says `FR1`.

Findings 6, 7, 8, and 11 were left as proposals here, since each changes behavior; all four were
decided and applied in the [over-constraint audit](over-constraint-audit.md) — the implementer brief
lost what `CLAUDE.md` already mandates, `CLAUDE.md` lost its operational detail, model routing
collapsed to one source, and "ask questions" became `NEEDS_CONTEXT`.

Rule 8 is the one this repo should sit with longest. keel is built out of "never" clauses, and the
article's position is that a current model applies judgment without them — every rule kept is a
claim that judgment would fail here. Auditing that claim, clause by clause, is the over-constraint
item, and this note is its input.

See also: [gates vs skills](gates-vs-skills.md), [execution mode routing](execution-mode-routing.md),
[verification contract](verification-contract.md).
