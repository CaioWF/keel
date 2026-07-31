---
type: design-note
title: CI and server-side gates
description: Why keel's own CI runs only the doc-layer gates plus a rationale check, why the phase gate could not be ported literally, and why the API-key review tier was deferred
---

# Design note: CI and server-side gates

**Every gate keel ships is client-side.** `phase-gate`, `precommit-gate`,
`secrets-guard`, `destructive-guard` and `slop-guard` live in `.claude/hooks/` —
one machine, and only while the human is inside Claude Code. A commit pushed from
a plain git client, a second machine, or the GitHub web UI passes through all of
them untouched. CI is the half that cannot be skipped.

## What the repo actually looked like

Measured before designing, not assumed:

- **No `.github/` at all.** keel shipped 8 gates and 817 assertions and ran none
  of them on push.
- **One pull request, ever** (#1, merged 2026-07-07). Work lands directly on
  `main`. A workflow triggered only on `pull_request` would fire about once a
  month, so both events are wired.
- **`origin` was sixteen commits behind `main`.** CI on a repo that rarely receives a
  push is worth exactly what the pushing habit is worth. The workflow does not
  fix that; it makes the gap visible.
- **The repo is public**, so standard-runner minutes are free. Cost was never the
  constraint.

## Scope: the doc layer, and nothing that needs a key

`run-gates.sh` detects its stack at runtime, and keel has neither a
`package.json` nor a `Makefile` — so on keel itself it already resolves to the
doc-layer checks alone (`audit-structure`, `eval-spec-fidelity`,
`validate-mermaid`, OKF index freshness). No `--docs-only` flag was needed. That
flag becomes real only if a pack ever installs this workflow into a project that
*does* have lint and tests, and building it now would be an option constructed
before its second use.

That scoping is also the anti-goal: running a project's full lint/test/build in
a keel-installed workflow duplicates CI the project already has, and goes red on
services and env keel knows nothing about. A gate that goes red for reasons
unrelated to its purpose gets switched off, and takes the credibility of the
other gates with it — the failure mode measured in
[over-constraint audit](over-constraint-audit.md).

**No secret is read by any job.** Automated review via the Claude Code Action
needs `ANTHROPIC_API_KEY`, and on a *public* repo that tier is not merely a cost
question: pull requests from forks do not receive secrets by design, so the job
would silently do nothing for exactly the contributors it was meant to serve.
The workaround, `pull_request_target`, runs fork-authored code with access to
secrets — a well-known footgun. If that tier is ever added it arrives as its own
workflow file with its own decision about forks, never as a line appended here.

## The rationale check

The phase gate could not be ported literally: **keel does not bootstrap itself.**
There is no `.specify/`, no `specs/<feature>/`, and `phase()`
(`core/claude/hooks/_lib.mjs`) keys on exactly those. What keel does have is a
convention it follows without enforcement — every substantive change ships a
design note or a plan. Fifteen of them, and counting.

So `ci/rationale-check.mjs` enforces that convention rather than an imported one:

| | |
|---|---|
| Payload | `core/`, `lib/`, `bootstrap.sh` |
| Reasoning | `docs/design-notes/`, `docs/plans/`, `docs/specs/` |
| Rule | payload changed and no reasoning changed → fail |
| Door (pull request) | the `trivial` label |
| Door (direct push) | `[trivial]` in a commit message |

Two doors because the two flows can express different things: a label exists only
on a pull request, and most of this repo's work never becomes one.

The failure message prints both doors. A hatch nobody knows about is a hatch that
does not exist — the same conclusion the trivial path reached for `phase-gate`.

**It lives in `ci/`, not `core/gates/`.** `bootstrap.sh` copies that whole tree
into every project, and this check only makes sense against keel's own layout.
Shipping it there would plant a second dead seam beside the `ts-clean-arch`
detection that has been a documented no-op since Plan 1.

**An unresolvable base ref skips instead of failing.** A branch's first push sends
an all-zero `before`, and a force-push leaves one unreachable. Failing there would
block on CI plumbing rather than on discipline, which is how a gate teaches people
to route around it. Same principle as `destructive-guard` degrading to *allow*
when it cannot decide.

## Deliberately not adopted

- **The generic `specs/<feature>/plan.md` check.** It is the right rule for a
  bootstrapped project and the wrong one here — it would run against nothing in
  keel's own repo, which is payload for a pack that does not exist yet.
- **A layout-detecting hybrid** (specs when `.specify/` exists, docs otherwise).
  Generalising over a single real case is the trap this repo already measured.
- **A `--docs-only` mode**, for the reason above.
- **Branch protection as the enforcement point.** The checks have to earn trust by
  running green for a while first; requiring them before that converts a new gate
  into an obstacle on day one.

## Related

- [Gate vs skill](gates-vs-skills.md) — where a concern belongs; this note adds the client/server axis
- [Over-constraint audit](over-constraint-audit.md) — the declared-door pattern and the cost of gates that block trivia
