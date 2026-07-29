---
type: design-note
title: Parallel work visibility
description: Why keel-watch renders repo state instead of tailing agent logs, and why the tmux layout is a thin wrapper over a renderer that works without it
---

# Design note: watching parallel work

`dispatch-parallel` fans a batch of disjoint tasks out to implementers, each isolated in its own
worktree. The controller gets their reports; the human gets nothing until it is over. This note
covers what closed that gap and, more usefully, what could not.

## The premise that did not survive contact

The idea came in as "one pane per parallel development, `tail -f` its log", modelled on a project
whose `scripts/` had a `spawn-detached.mjs`. That shape assumes keel spawns the workers. It does
not. Parallel implementers are dispatched through the harness's Agent tool with
`isolation: "worktree"`; there is no keel-owned process, no PID, and no log file to follow.

What the repo does expose while a batch runs:

| Signal | Source | Granularity |
|---|---|---|
| tasks done / total | `specs/<feature>/tasks.md` checkboxes | per completed task |
| tasks in flight | `<git-common-dir>/sdd/<feature>/task-N-brief.md` with no `task-N-report.md` | per dispatch |
| what finished cleanly | `progress.md` ledger | per clean review |
| where work is happening | `git worktree list` + per-worktree dirty count | live |

So the honest product is a **state renderer**, not a log viewer. `scripts/watch-status.mjs` prints
that table; a brief without a report is the closest thing to "running now" the system has, and it
is genuinely useful — it also exposes a task whose implementer died, which no ledger line would.

## Read-only, and one definition of the phase

The renderer writes nothing: it reads specs, the dispatch dir, and git. A watcher that mutated the
run it observes would be a debugging problem of its own.

It imports `activeFeature` and `phase` from `.claude/hooks/_lib.mjs` rather than re-deriving them.
The phase machine already exists; a second copy in a script would drift from the hooks the moment
either changed. A project without that file is not a keel project, and the renderer says so instead
of rendering an empty screen.

## tmux is the wrapper, not the product

`scripts/keel-watch.sh` opens a session with the status pane plus a shell per extra worktree, capped
at three panes so the layout stays readable, with the rest listed in the status pane. Without tmux —
or with `--no-tmux` — it runs the same renderer in the current terminal, and `--once` prints one
frame and exits.

The per-worktree panes are shells, not tails: they put the human *in* the worktree to inspect or
drive a session there. That is the part tmux is actually good at.

## Deliberately not done

- **No headless agent runner.** keel could spawn `claude -p` per worktree and tail those logs, but
  that duplicates the dispatch the Agent tool already does, and splits parallelism into two
  mechanisms that would drift.
- **No polling daemon or state file.** Each render is a fresh read; there is no cache to
  invalidate and nothing to clean up.
- **No interactive attach into a running agent.** The harness owns those sessions.
- **No progress bar per task.** The system has no sub-task signal to honestly draw one from.

Related: [Execution mode routing](execution-mode-routing.md) (which decides when work goes parallel
at all), [Living project docs](living-project-docs.md) (the `## Environment` block that names this
command), [Gates vs skills](gates-vs-skills.md).
