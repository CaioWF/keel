---
type: design-note
title: Install configuration
description: Why bootstrap stays non-interactive, why --configure is a separate command, and where the architecture style choice belongs instead
---

# Design note: configuring an install

keel has two kinds of optional thing, and they want different install semantics. Bundling
them into one question is what makes "should the installer prompt?" feel unanswerable.

| | Architecture **style** | Optional **disciplines** |
|---|---|---|
| Examples | Clean, Hexagonal, Onion, Layered | packs (`ship`, `ui-review`, …), agent views |
| Cardinality | exactly one per project, mutually exclusive | any number, combinable |
| Reversibility | hard to reverse; wants a recorded rationale | add or drop later at no cost |
| Home | `constitution.md` plus an ADR | `.specify/keel.json` plus the pack's own install |

## Why the install path is not interactive

`bootstrap.sh` is run by the test suite, by CI, and by the agent itself — with stdin and
stdout captured (`>/dev/null`, `OUT=$(...)`). A `read` in that path does not prompt; it
hangs or swallows unrelated input. So an interactive installer can never be the only
path: it always needs a flag equivalent for every answer, a `[ -t 0 ]` guard, and a way
to avoid re-asking on every `--force` update.

Those flags already exist (`--pack=`, `--agent=`, `--all`), and the manifest already
remembers the answers. What was missing was not a mechanism — it was **discovery**.
`packs/ship` is documented as "opt-in ONLY, never auto-detected", which means nothing
surfaces it, and nobody reads `--help`.

So the split is:

- **install** stays deterministic and silent about input; it ends by *naming* the packs
  it did not install and pointing at `--configure`.
- **`--configure`** is its own command. Whoever types it knows it will ask. It never runs
  during an install or an update, so CI and the agent are unaffected.

## Why `--configure` does not ask about architecture style

Install is the moment of **least information**. The project is often empty: no domain, no
code, no product brief. A `read` prompt cannot read the repo, cannot explain the
difference between ports-and-adapters and concentric rings, and cannot record *why* the
answer was chosen. Worse, `bootstrap.sh` is re-executable — a style question in that path
would either re-interrogate on every update or change an architectural decision silently.

keel already owns a better interviewer: `constitution-writer` runs in-session, where the
agent reads the codebase, explains the trade-off, and the answer lands in the constitution
(injected at SessionStart) with an ADR carrying the rationale. That is where style goes.
See [architecture styles](../plans/2026-07-15-architecture-styles.md), which reached the
same conclusion from the other direction and rejected an `--arch` install flag.

## What `--configure` does

Reads `.specify/keel.json`, renders every `packs/*/install.sh` found on disk plus the
available agent views, pre-checked to match what is already recorded. Numbers toggle,
Enter applies, `q` aborts. It then runs only the newly selected pack installs, re-emits
views if agents changed, and rewrites the manifest.

Design points worth keeping:

- **Enumerated from disk.** A pack added to the repo appears in the menu with no edit
  here, so the menu cannot drift from what actually ships.
- **Pre-checked from the manifest.** Confirming without touching anything is a no-op.
  Seeding an empty selection would turn "I just wanted to look" into an uninstall.
- **Two guards, specific first.** A directory with no `.specify/keel.json` is refused
  before the TTY check, because pointing `--configure` at the wrong directory is worth
  saying out loud even from a pipe. The TTY refusal names `--pack=`/`--agent=` rather
  than only complaining.
- **Deselection is honest.** keel has no uninstall. Unchecking a pack drops the manifest
  record and says so; it does not pretend files were removed. Auto-detected packs return
  on the next bootstrap, and the message says that too.
- **Sourceable.** The set arithmetic lives in functions guarded by `BASH_SOURCE`, so the
  tests exercise it directly; only the menu itself needs a pty.

## The banner

`lib/ui.sh` prints the wordmark, gated on stdout being a TTY. That one guard does double
duty: it is what makes the banner appear for a human, and it is what keeps it out of the
captured output every test and CI run depends on. Non-TTY output is byte-identical to
before the banner existed, and a test pins that. Colour additionally honours `NO_COLOR`
and `TERM=dumb`; a non-UTF-8 locale falls back to plain ASCII instead of mojibake.

## Related

- [Gate vs skill](gates-vs-skills.md) — the mechanical-vs-judgment split this follows
- [Concept layer](concepts-layer.md) — where guides live vs where enforcement packs live
- [Architecture styles](../plans/2026-07-15-architecture-styles.md) — the style choice, and why it is not an install flag
