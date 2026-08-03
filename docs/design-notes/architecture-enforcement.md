---
type: design-note
title: Architecture enforcement
description: Why the dependency rule finally got a mechanical check, why it ships as an opt-in pack with a zero-dep checker, and the pack.d seam that made it possible
---

# Design note: enforcing the dependency rule

The [concept layer](concepts-layer.md) always described two halves: an agnostic guide saying
what to build, and a pack imposing it mechanically. Only the first half was ever built.
`bootstrap.sh` carried a seam that detected TypeScript, printed
`TS project detected — ts-clean-arch pack`, and then did nothing, because the pack it pointed
at never shipped. It printed that line for the entire life of the repo.

That is the gap this closes, and the reason it matters is not tidiness. Research on
agent-written systems reports code that "appears modular on the surface while violating deeper
modular principles" — the failure is invisible to review precisely because the shape looks
right. keel had five architecture guides and not one of them could fail a commit. More prose
was never going to fix a surface-level correctness problem.

## Named after the rule, not the style

The seam's name, `ts-clean-arch`, was wrong twice.

**The language prefix.** No other pack has one. `stack-conventions` is detected by the same TS
signal and is not called `ts-conventions`. Packs are named for what they do.

**The style name.** A linter checks import direction. Clean, Hexagonal and Onion share that
rule exactly — they differ in vocabulary, which is why they are one guide here and not three. A
pack called `clean-arch` would read as wrong in a project that calls itself hexagonal while
obeying an identical constraint.

Hence `architecture-gates`, with the check inside named `dependency-rule`, after the
constitution line it makes mechanical.

## Opt-in, and why that changed

The dead seam auto-detected a TS signal. The pack does not, for a reason the seam never had to
face because it never did anything: this pack **writes config into the project and adds a gate
that can fail a build**. `stack-conventions` auto-installs on the same signal, but it only adds
advisory skills — nothing it does can turn a build red. Installing enforcement is a delivery
choice, not a stack fact, which is the reasoning that already makes `ship` opt-in.

Opt-in used to carry one real objection: nobody would find it. That objection died with
`--configure` and the not-installed list printed at the end of an install (see
[install configuration](install-configuration.md)). Discovery is handled, so opt-in costs
nothing.

## The `pack.d` seam

`run-gates.sh` ran a hardcoded list of doc gates, and `copy_tree` rewrites that file on every
`--force`. A pack appending to it would be erased by the next update — exactly why
`review-lenses.txt` and `impl-conventions.txt` are living registries seeded with
`copy_file_once` rather than edits to core files.

Gates now get the same treatment: core sweeps `.specify/gates/pack.d/*.mjs`, a pack drops a
file in, and `copy_tree` never deletes what it did not ship, so the file survives updates. Any
future enforcement pack uses the same door.

## Zero-dep, and honest about its limits

The obvious implementation is to ship a `dependency-cruiser` config. Rejected: the README
states "Requires Node. No other dependency", and a pack demanding `npm i -D` would break that
invariant for the first time — and fail outright in a project that has not run `npm install`.

So the gate is a checker with no dependencies, and its scope is deliberately one invariant:
given a declared layer map, no file in an inner layer imports an outer one. No cycle detection,
no orphan analysis, no graph output. The guide names the real tools (dependency-cruiser,
import-linter, ArchUnit) for teams that want those; this does not pretend to replace them.

Decisions inside the checker worth keeping:

- **Skip, never fail, when there is nothing to check** — no config, no root directory, no
  matching files. Failing on plumbing is how a gate teaches people to ignore it, the same
  principle behind the destructive guard degrading to allow and the CI rationale check skipping
  an unresolvable base.
- **Files outside every declared layer are unchecked.** The composition root exists precisely
  to wire concrete infra into use cases; forbidding that would forbid assembling the
  application at all.
- **External packages are an allow-list, not a deny-list.** `domain` declares what it may
  import and defaults to nothing, so an ORM added to the project next year is caught rather
  than passing because nobody remembered to forbid it.
- **Comments are blanked before matching, preserving line numbers**, so a commented-out import
  is not a violation and the report still points at the real line.
- **The layer map is seeded once and never overwritten, not even under `--force`.** It describes
  the project's own tree; refreshing it from the template would discard real layer names and
  re-point the gate at directories that may not exist.

## What this does not do

Style selection (Clean, Hexagonal, Onion) stays out of the installer and out of the pack. It is
one mutually exclusive, hard-to-reverse choice that wants a rationale, so it belongs in the
constitution plus an ADR. The pack does not care which vocabulary a project uses: it enforces
direction, and the layer names come from the project's own config.

## Related

- [Concept layer](concepts-layer.md) — the recipe whose fourth slot this fills
- [Gate vs skill](gates-vs-skills.md) — the mechanical-vs-judgment split
- [Install configuration](install-configuration.md) — why opt-in is now discoverable
