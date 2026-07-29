---
type: design-note
title: Prose slop-guard
description: Why keel scans written prose for AI-writing tells with an advisory PostToolUse hook, why em-dash is not a rule, and why it warns instead of blocking
---

# Design note: the prose slop-guard

`core/claude/hooks/slop-guard.mjs` reads every Write/Edit payload, extracts the prose (markdown
minus fenced code, or the comments in a code file), and reports AI-writing tells back to the agent
once one write carries 3 or more. Nothing is blocked and nobody is asked to approve.

## Why a hook at all

keel already states the rule (`CLAUDE.md` → `## Prose`, `## Comments`) and reviews prose as judgment
(`code-review`, `simplify`). Neither catches the tells reliably: a rule in the system prompt decays
over a long session, and review happens once, late, over a large diff. The tells are lexical and
structural — the mechanizable half of the concern, which by keel's own
[gate vs skill](gates-vs-skills.md) rule belongs in deterministic code, fired at the moment of
writing, where the fix is a rewrite of a paragraph the agent still has in context.

## Why advisory, not blocking

A `PostToolUse` hook cannot block: the write already happened. Its only lever is `exit 2`, which
sends stderr to the agent. That constraint fits the subject:

- Slop detection is heuristic. Every published detector warns that false positives are frequent and
  that these signals should not drive high-stakes decisions.
- The alternative — `PreToolUse` with `permissionDecision: "ask"` — would interrupt a human for
  approval on legitimate prose. Wrong trade for a style concern.
- A threshold (3 distinct tells by default, `KEEL_SLOP_THRESHOLD`) keeps one stray phrase from
  costing anything. `KEEL_SLOP_OFF=1` turns it off completely.

The governing rule: a guard that cries wolf gets disabled, and then it protects nothing. A test
asserts that keel's own skills, notes, and templates trip zero warnings.

## Why em-dash is NOT a rule

A deliberate omission, and the first thing a future contributor will try to "fix". Through 2024 a
wall of em-dashes was a usable signal; current models suppress them, so presence or absence proves
nothing, while em-dash is common in legitimate human prose. Including it would produce most of the
false positives and bury the structural signals in noise. Structural tells (`not just X, but Y`,
throat-clearing, significance-claiming) are both more reliable and harder to game, so they carry the
rule set instead.

## Scope: markdown prose and code comments

- Markdown: fenced blocks and inline code are blanked out, keeping line numbers honest, so a code
  example cannot trip a prose rule. Blockquotes are kept — instruction blocks in templates are prose
  someone wrote.
- Code files: comment text only, per extension (`//`, `#`, `--`, `/* */`, `"""`, `<!-- -->`). A
  string literal containing `it is worth noting` does not count.
- Two rules are markdown-only: decorative emoji in headings (⚠ ℹ ✔ ✖ are signposts, not ornament)
  and Title-Case headings at H2+ (an H1 document title in Title Case is ordinary).
- Vocabulary is counted by distinct word, so one repeated word cannot reach the threshold alone.

## Prior art (scanned 2026-07-25)

- **Wikipedia's "Signs of AI writing"** is the canonical enumeration: vocabulary, negative
  parallelism, rule of three, undue significance, promotional register, vague attribution, formulaic
  conclusions, emoji-as-formatting, Title Case headings. The rule set here is the subset that stays
  precise on technical prose.
- **no-slop** (13 rules) and **slop-gate** (zero-dep CLI, ~40 tells in JSON rule packs) implement the
  same idea as linters; **Vale** is the general prose linter with severity levels. keel stays
  zero-dep, so the detector is a table of regexes inside the hook rather than a dependency.
- **`iCodeCraft/anti-slop`**, the reference in the original TODO, turned out to be about *code* slop,
  not prose: minimal diffs, no unrequested dependencies, no invented layer directories, no obvious
  comments. keel covers that ground already with `simplify`, `architecture/references/minimalism.md` (the
  laziness ladder), and `analyze`'s over-engineering check. It informed nothing here.

## Deliberately not done

- **No review lens.** A third lens beside `code-review` and `security-review` would re-read the whole
  diff to find what the hook already caught at write time.
- **No commit-message scan.** It needs a second `PreToolUse(Bash)` matcher beside the precommit-gate,
  for a surface write-time coverage mostly reaches anyway.
- **No blocking tier.** See above. If a project truly wants prose gated, the honest place is a
  `PreToolUse` variant, chosen explicitly rather than shipped as a default.

See also: [gates vs skills](gates-vs-skills.md), [verification contract](verification-contract.md).
