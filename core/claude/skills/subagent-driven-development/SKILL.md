---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

## No-Commit Rule (overrides any per-task-commit pattern)

This project commits at feature/milestone boundaries with explicit human
approval — never per task, per step, or per TDD cycle. This changes how
review works compared to a commit-per-task workflow:

- **Dispatched implementer subagents NEVER run `git` and NEVER commit.**
  They implement, test, and report only. A subagent that proposes to commit
  has misunderstood its brief — correct it and re-dispatch if needed.
- **The controller (you) does not commit per task either.** Commits happen
  only at a milestone, with explicit human approval, after all tasks in the
  plan are done and reviewed.
- Because there are no per-task commits to diff between, the review
  baseline is a **git tree snapshot** taken with `git write-tree` before
  each task (no commit object, no ref, no working-tree mutation — it just
  writes the current index as a tree object and prints its SHA). Each
  task's review diff is computed against the previous snapshot tree:
  `git diff <previous-tree-sha> <current-tree-sha>`. This is exactly the
  mechanism used to build this very feature — every task in this plan was
  snapshotted with `write-tree` and reviewed via tree-to-tree diff, not
  commit-to-commit diff.
- Before dispatching Task 1, take the baseline snapshot: `git add -A && git
  write-tree` (this requires the changes to be staged so the tree reflects
  them; if you don't want to disturb the working tree's stage, use a
  temporary `GIT_INDEX_FILE` pointed at a scratch index instead). Record the
  printed tree SHA as `BASE`.
- After each task, stage again and snapshot again to get `HEAD` for that
  task's review. After review passes, `HEAD` becomes `BASE` for the next
  task.
- At the end of all tasks, the final whole-branch review diffs the
  milestone's starting tree snapshot against the last task's tree snapshot
  — still no commits involved.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
}
```

- Fresh subagent per task (no context pollution)
- Review after each task (spec compliance + code quality), broad review at the end
- Faster iteration (no human-in-loop between tasks)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Snapshot tree (git write-tree) as task BASE" [shape=box];
        "Dispatch implementer subagent (./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests, self-reviews, reports" [shape=box];
        "Snapshot tree again as task HEAD, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
        "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
        "Dispatch fix subagent for Critical/Important findings" [shape=box];
        "Mark task complete in todo list and progress ledger" [shape=box];
    }

    "Read plan, note context and global constraints, create todos" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Dispatch final whole-branch reviewer subagent" [shape=box];
    "Report milestone ready; propose commit message and wait for human approval" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, note context and global constraints, create todos" -> "Snapshot tree (git write-tree) as task BASE";
    "Snapshot tree (git write-tree) as task BASE" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, self-reviews, reports" [label="no"];
    "Implementer subagent implements, tests, self-reviews, reports" -> "Snapshot tree again as task HEAD, dispatch task reviewer subagent (./task-reviewer-prompt.md)";
    "Snapshot tree again as task HEAD, dispatch task reviewer subagent (./task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
    "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
    "Dispatch fix subagent for Critical/Important findings" -> "Snapshot tree again as task HEAD, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [label="re-review"];
    "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
    "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
    "More tasks remain?" -> "Snapshot tree (git write-tree) as task BASE" [label="yes"];
    "More tasks remain?" -> "Dispatch final whole-branch reviewer subagent" [label="no"];
    "Dispatch final whole-branch reviewer subagent" -> "Report milestone ready; propose commit message and wait for human approval";
}
```

## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts:

- tasks that contradict each other or the plan's Global Constraints
- anything the plan explicitly mandates that the review rubric treats as a
  defect (a test that asserts nothing, verbatim duplication of a logic block)

Present everything you find to your human partner as one batched question —
each finding beside the plan text that mandates it, asking which governs —
before execution begins, not one interrupt per discovery mid-plan. If the
scan is clean, proceed without comment. The review loop remains the net for
conflicts that only emerge from implementation.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture and design tasks**: use the most capable available model.
The final whole-branch review is one of these — dispatch it on the most
capable available model, not the session default.

**Review tasks**: choose the model with the same judgment, scaled to the
diff's size, complexity, and risk. A small mechanical diff does not need the
most capable model; a subtle concurrency change does.

**Always specify the model explicitly when dispatching a subagent.** An
omitted model inherits your session's model — often the most capable and
most expensive — which silently defeats this section.

**Turn count beats token price.** Wall-clock and context cost scale with how
many turns a subagent takes, and the cheapest models routinely take 2-3× the
turns on multi-step work — costing more overall. Use a mid-tier model as the
floor for reviewers and for implementers working from prose descriptions.
When the task's plan text contains the complete code to write, the
implementation is transcription plus testing: use the cheapest tier for
that implementer. Single-file mechanical fixes also take the cheapest tier.

**Task complexity signals (implementation tasks):**
- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Snapshot the tree (`git add -A && git write-tree`) to get this
task's HEAD, then dispatch the task reviewer with the previous task's tree
SHA as BASE and this snapshot as HEAD — never reuse an older snapshot,
which silently drops work from prior tasks in the diff.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Handling Reviewer ⚠️ Items

The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
that live in unchanged code or span tasks. These do not block the rest of the
review, but you must resolve each one yourself before marking the task
complete: you hold the plan and cross-task context the reviewer
lacks. If you confirm an item is a real gap, treat it as a failed spec
review — send it back to the implementer and re-review.

## Constructing Reviewer Prompts

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. When you fill a reviewer template:

- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the plan's Global
  Constraints section or the spec: exact values, exact formats, and the
  stated relationships between components ("same layout as X", "matches
  Y"). The reviewer's template already carries the process rules (YAGNI,
  test hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
- Hand the reviewer its diff as a file: `git diff BASE_TREE HEAD_TREE >
  <unique-path>` (BASE_TREE/HEAD_TREE are the `write-tree` SHAs from this
  task, not commit SHAs), plus `git diff --stat BASE_TREE HEAD_TREE` for the
  summary, both redirected into one uniquely named file. The output never
  enters your own context, and the reviewer sees the stat summary and full
  diff with context in one Read call.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches — a real session's dispatch hit 42k chars of which 99%
  was pasted history. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- Dispatch fix subagents for Critical and Important findings. Record Minor
  findings in the progress ledger as you go, and point the final
  whole-branch review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is the human's decision, like any plan
  contradiction: present the finding and the plan text, ask which governs.
  Do not dismiss the finding because the plan mandates it, and do not
  dispatch a fix that contradicts the plan without asking.
- The final whole-branch review gets a package too: `git diff
  MILESTONE_START_TREE LAST_TASK_TREE` (MILESTONE_START_TREE = the snapshot
  taken before Task 1) into one file, so the final reviewer reads one diff
  instead of re-deriving the milestone's full change set with git commands.
- Every fix dispatch carries the implementer contract: the fix subagent
  re-runs the tests covering its change and reports the results. Name the
  covering test files in the dispatch — a one-line fix does not need the
  whole suite. Before re-dispatching the reviewer, confirm the fix report
  contains the covering tests, the command run, and the output; dispatch
  the re-review once all three are present.
- If the final whole-branch review returns findings, dispatch ONE fix
  subagent with the complete findings list — not one fixer per finding.
  Per-finding fixers each rebuild context and re-run suites; a real
  session's final-review fix wave cost more than all its tasks combined.

## File Handoffs

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files:

- **Task brief:** before dispatching an implementer, extract the task's full
  text from the plan into a uniquely named file (e.g.
  `specs/<feature>/task-N-brief.md`). Compose the dispatch so the brief
  stays the single source of requirements. Your dispatch should contain:
  (1) one line on where this task fits in the project; (2) the brief path,
  introduced as "read this first — it is your requirements, with the exact
  values to use verbatim"; (3) interfaces and decisions from earlier tasks
  that the brief cannot know; (4) your resolution of any ambiguity you
  noticed in the brief; (5) the report-file path and report contract; (6)
  the explicit instruction that the subagent must NOT run git or commit —
  implement, test, report only. Exact values (numbers, magic strings,
  signatures, test cases) appear only in the brief.
- **Report file:** name the implementer's report file after the brief
  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
  the dispatch prompt. The implementer writes the full report there and
  returns only status, files changed, a one-line test summary, and concerns
  — never commits, since there is nothing to commit to.
- **Reviewer inputs:** the task reviewer gets three paths — the same brief
  file, the report file, and the tree-diff package — plus the global
  constraints that bind the task.
- Fix dispatches append their fix report (with test results) to the same
  report file and return a short summary; re-reviews read the updated file.

## Durable Progress

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences — the single most expensive failure observed. Track progress in
a ledger file, not only in todos.

- At skill start, check for a ledger, e.g.
  `specs/<active-feature>/progress.md`. Tasks listed there as complete are
  DONE — do not re-dispatch them; resume at the first task not marked
  complete.
- When a task's review comes back clean, append one line to the ledger in
  the same message as your other bookkeeping:
  `Task N: complete (tree <base7>..<head7>, review clean)` — using the
  `write-tree` SHAs, since there are no commits to cite.
- The ledger is your recovery map: the tree SHAs it names are real git
  objects even when your context no longer remembers creating them. After
  compaction, trust the ledger over your own recollection (tree objects are
  not reachable from refs, so they can be garbage-collected — treat the
  ledger as a record of what happened, not as a guaranteed-retrievable
  blob store).

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
- Final whole-branch review: build the same kind of prompt inline — full
  milestone tree-diff package, global constraints, spec-compliance plus
  code-quality rubric exactly as in task-reviewer-prompt.md, scoped to the
  whole milestone instead of one task.

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: specs/feature/plan.md]
[Create todos for all tasks]
[git add -A && git write-tree -> MILESTONE_START = abc123...]

Task 1: Hook installation script

[Extract Task 1 brief; BASE = MILESTONE_START; dispatch implementer with brief + report paths + context + no-commit instruction]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.config/harness/hooks/)"

Implementer: "Got it. Implementing now..."
[Later] Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Reported DONE (no commit)

[git add -A && git write-tree -> HEAD1 = def456...]
[Dispatch task reviewer with diff BASE..HEAD1]
Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.

[Mark Task 1 complete; ledger: "Task 1: complete (tree abc123..def456, review clean)"]

Task 2: Recovery modes

[Extract Task 2 brief; BASE = HEAD1; dispatch implementer with brief + report paths + context]

Implementer: [No questions, proceeds]
Implementer:
  - Added verify/repair modes
  - 8/8 tests passing
  - Self-review: All good
  - Reported DONE (no commit)

[git add -A && git write-tree -> HEAD2]
[Dispatch task reviewer with diff HEAD1..HEAD2]
Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)
  Issues (Important): Magic number (100)

[Dispatch fix subagent with all findings]
Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant

[git add -A && git write-tree -> HEAD2']
[Task reviewer reviews again with diff HEAD1..HEAD2']
Task reviewer: Spec ✅. Task quality: Approved.

[Mark Task 2 complete; ledger updated]

...

[After all tasks: git write-tree -> MILESTONE_END]
[Dispatch final whole-branch reviewer with diff MILESTONE_START..MILESTONE_END]
Final reviewer: All requirements met, ready to merge

[Report milestone ready; propose commit message(s); wait for explicit human approval before running git commit]
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**Efficiency gains:**
- Controller curates exactly what context is needed; bulk artifacts move
  as files, not pasted text
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)

**Quality gates:**
- Self-review catches issues before handoff
- Task review carries two verdicts: spec compliance and code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + reviewer per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Let any implementer or fix subagent run `git commit` (or any git mutating
  command) — they implement, test, and report only
- Commit per task from the controller side — commits happen only at a
  milestone, with explicit human approval
- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make a subagent read the whole plan file (hand it its task brief instead)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
  dispatch prompt ("treat it as Minor at most") — the plan's example code is
  a starting point, not evidence that its weaknesses were chosen
- Dispatch a task reviewer without a diff file — generate it first
  (`git diff BASE_TREE HEAD_TREE`) and name the path in the prompt
- Move to next task while the review has open Critical/Important issues
- Re-dispatch a task the progress ledger already marks complete — check
  the ledger (and the tree SHAs in it) after any compaction or resume

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing), if the human wants isolation for this milestone

**Subagents should use:**
- Standard TDD practice (red-green-refactor) for each task, per this
  project's own implementation skills
