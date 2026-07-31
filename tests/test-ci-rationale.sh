# CI rationale check (docs/design-notes/ci-server-side-gates.md): the server-side
# half of the phase gate — payload changes must arrive with recorded reasoning.
# Sourced by run.sh.
RC="$HERE/../ci/rationale-check.mjs"
WF="$HERE/../.github/workflows/ci.yml"

assert_file "$RC" "rationale check exists"
assert_file "$WF" "ci workflow exists"

SB="$(new_sandbox)"
mk_files() { printf '%s\n' "$@" > "$SB/files.txt"; }
mk_msgs() { printf '%s\n' "$@" > "$SB/msgs.txt"; }
run_rc() { node "$RC" --files "$SB/files.txt" "$@" > "$SB/out.txt" 2>&1; echo $?; }

# Nothing keel ships was touched — there is nothing to justify.
mk_files "tests/test-foo.sh" "README.md"
assert_eq "0" "$(run_rc)" "docs/tests-only change passes"
assert_contains "$SB/out.txt" "nothing to justify" "passing message names the reason"

# The case the gate exists for: shipped payload changed, no reasoning recorded.
mk_files "core/gates/run-gates.sh" "lib/emit-views.mjs"
assert_eq "1" "$(run_rc)" "payload change with no rationale fails"
assert_contains "$SB/out.txt" "core/gates/run-gates.sh" "failure names the offending file"

# A hatch nobody knows about is a hatch that does not exist — the block must
# announce both doors (over-constraint-audit.md).
assert_contains "$SB/out.txt" "trivial" "failure announces the trivial door"
assert_contains "$SB/out.txt" "docs/design-notes/" "failure names where rationale goes"

# Each rationale directory satisfies the check on its own.
for d in design-notes plans specs; do
  mk_files "core/gates/run-gates.sh" "docs/$d/note.md"
  assert_eq "0" "$(run_rc)" "docs/$d/ satisfies the rationale requirement"
done

# bootstrap.sh is payload too, even though it is a single file, not a tree.
mk_files "bootstrap.sh"
assert_eq "1" "$(run_rc)" "bootstrap.sh alone counts as payload"

# The declared door, in the two forms keel's flows can express. A label only
# exists on a pull request; a direct push to main has commit messages instead.
mk_files "core/gates/run-gates.sh"
assert_eq "0" "$(run_rc --labels trivial)" "the trivial label opens the door"
assert_eq "0" "$(run_rc --labels Trivial,bug)" "label matching ignores case and extra labels"
assert_eq "1" "$(run_rc --labels bug)" "an unrelated label does not open the door"

mk_msgs "fix(gates): typo in a comment" "[trivial]"
assert_eq "0" "$(run_rc --messages "$SB/msgs.txt")" "the [trivial] commit trailer opens the door"
mk_msgs "feat(gates): rewrite the resolver"
assert_eq "1" "$(run_rc --messages "$SB/msgs.txt")" "an ordinary commit message does not open the door"

# CI plumbing is not a discipline violation: a first push sends an all-zero
# "before" and a force-push leaves one unreachable. Blocking there would teach
# people the gate is noise.
node "$RC" --base 0000000000000000000000000000000000000000 > "$SB/out.txt" 2>&1
assert_eq "0" "$?" "an unresolvable base ref skips instead of failing"
assert_contains "$SB/out.txt" "not resolvable" "the skip says why"

# Reading the diff from git is the mode CI actually uses.
git -C "$SB" init -q 2>/dev/null
git -C "$SB" config user.email keel@test.local
git -C "$SB" config user.name keel-test
mkdir -p "$SB/core" "$SB/docs/design-notes"
printf 'seed\n' > "$SB/README.md"
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" commit -qm "seed" >/dev/null 2>&1
BASE="$(git -C "$SB" rev-parse HEAD)"
printf 'payload\n' > "$SB/core/thing.sh"
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" commit -qm "feat: add a thing" >/dev/null 2>&1
if node "$RC" --dir "$SB" --base "$BASE" --head HEAD > "$SB/out.txt" 2>&1; then
  fail "git mode fails an unjustified payload commit"
else
  pass "git mode fails an unjustified payload commit"
fi
printf 'why\n' > "$SB/docs/design-notes/why.md"
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" commit -qm "docs: record the reasoning" >/dev/null 2>&1
if node "$RC" --dir "$SB" --base "$BASE" --head HEAD > "$SB/out.txt" 2>&1; then
  pass "git mode passes once the reasoning lands in the range"
else
  fail "git mode passes once the reasoning lands in the range"
fi
rm -rf "$SB"

# The check is keel's own tooling. Shipping it through bootstrap would plant the
# dead seam this design deliberately avoids.
SB2="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB2" >/dev/null 2>&1
assert_nofile "$SB2/ci" "bootstrap does not ship the rationale check into projects"
assert_nofile "$SB2/.github" "bootstrap does not ship workflows into projects"
rm -rf "$SB2"

# The workflow runs what the baseline verified, on both events keel actually uses.
assert_contains "$WF" "tests/run.sh" "workflow runs the test suite"
assert_contains "$WF" "core/gates/run-gates.sh" "workflow runs the doc-layer gates"
assert_contains "$WF" "ci/rationale-check.mjs" "workflow runs the rationale check"
assert_contains "$WF" "pull_request:" "workflow triggers on pull requests"
assert_contains "$WF" "push:" "workflow triggers on pushes — the flow this repo actually uses"
assert_contains "$WF" "fetch-depth: 0" "rationale job fetches history so a diff range resolves"
