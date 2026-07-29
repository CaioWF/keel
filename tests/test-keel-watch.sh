# keel-watch (docs/design-notes/parallel-work-visibility.md): read-only status of
# work in flight — features, dispatched tasks, ledger, worktrees. Sourced by run.sh.
WS="$HERE/../core/scripts/watch-status.mjs"
KW="$HERE/../core/scripts/keel-watch.sh"

assert_file "$WS" "watch-status renderer exists"
assert_file "$KW" "keel-watch launcher exists"

# Not a keel project ⇒ refuse rather than render an empty screen.
SBX="$(new_sandbox)"
if node "$WS" --dir "$SBX" >/dev/null 2>&1; then
  fail "watch-status refuses a non-keel dir"
else
  pass "watch-status refuses a non-keel dir"
fi
rm -rf "$SBX"

# A bootstrapped repo mid-implementation: one task done, two dispatched, one report back.
SB="$(new_sandbox)"
git -C "$SB" init -q 2>/dev/null
git -C "$SB" config user.email keel@test.local
git -C "$SB" config user.name keel-test
bash "$HERE/../bootstrap.sh" --dir "$SB" >/dev/null 2>&1

assert_file "$SB/scripts/keel-watch.sh" "bootstrap installs keel-watch"
assert_file "$SB/scripts/watch-status.mjs" "bootstrap installs the status renderer"
[ -x "$SB/scripts/keel-watch.sh" ] && pass "keel-watch is executable" || fail "keel-watch is executable"

mkdir -p "$SB/specs/003-demo"
printf -- '- [x] Task 1: seed\n- [ ] Task 2: api\n- [ ] Task 3: ui\n' > "$SB/specs/003-demo/tasks.md"
for f in prd spec plan; do printf -- '# %s\n' "$f" > "$SB/specs/003-demo/$f.md"; done
printf '003-demo\n' > "$SB/.specify/state"

SDD="$SB/.git/sdd/003-demo"
mkdir -p "$SDD"
printf -- '# task 1\n' > "$SDD/task-1-brief.md"
printf -- '# report 1\n' > "$SDD/task-1-report.md"
printf -- '# task 2\n' > "$SDD/task-2-brief.md"
printf -- '# task 3\n' > "$SDD/task-3-brief.md"
printf 'Task 1: complete (tree aaaaaaa..bbbbbbb, review clean)\n' > "$SDD/progress.md"

OUT="$SB/out.txt"
node "$WS" --dir "$SB" > "$OUT" 2>&1
assert_contains "$OUT" "003-demo" "status lists the feature"
assert_contains "$OUT" "implement" "status shows the phase"
assert_contains "$OUT" "1/3" "status counts top-level tasks"
assert_contains "$OUT" "task-2" "a brief with no report reads as in flight"
assert_contains "$OUT" "task-3" "every in-flight task is listed"
if grep -qE "task-1 \(" "$OUT"; then fail "a task with a report is not in flight"; else pass "a task with a report is not in flight"; fi
assert_contains "$OUT" "review clean" "status tails the progress ledger"
assert_contains "$OUT" "worktrees" "status lists worktrees"

# The launcher's --once path renders the same status without tmux.
OUT2="$SB/out2.txt"
bash "$KW" --dir "$SB" --once > "$OUT2" 2>&1
assert_contains "$OUT2" "003-demo" "keel-watch --once renders the status"
assert_contains "$OUT2" "keel watch" "keel-watch --once prints the header"

# A second worktree shows up with its branch — the parallel case this exists for.
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" commit -qm "seed" >/dev/null 2>&1
git -C "$SB" worktree add -q -b feat-demo "$SB/.worktrees/demo" >/dev/null 2>&1
OUT3="$SB/out3.txt"
node "$WS" --dir "$SB" > "$OUT3" 2>&1
assert_contains "$OUT3" "feat-demo" "status names the worktree's branch"
assert_contains "$OUT3" ".worktrees/demo" "status names the worktree path"
git -C "$SB" worktree remove --force "$SB/.worktrees/demo" >/dev/null 2>&1
rm -rf "$SB"

# Wiring: the command is where a human looks for it.
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "keel-watch.sh" "CLAUDE.md environment block names the watch command"
