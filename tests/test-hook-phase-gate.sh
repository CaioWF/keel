H="$HERE/../core/claude/hooks/phase-gate.mjs"
S="$(new_sandbox)"; mkdir -p "$S/specs/001-foo" "$S/src" "$S/.specify"; echo "001-foo" > "$S/.specify/state"

# editing a spec artifact is always allowed
printf '{"cwd":"%s","tool_input":{"file_path":"%s/specs/001-foo/spec.md"}}' "$S" "$S" | node "$H"; assert_eq "0" "$?" "editing spec artifact allowed"

# editing code with no approved spec/plan -> blocked (exit 2)
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "code edit blocked without approval"

# a nested dir coincidentally named docs/specs must NOT escape the gate
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/docs/util.js"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "nested src/docs does not bypass gate"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/specs/x.js"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "nested src/specs does not bypass gate"

# approve spec + plan -> allowed
printf -- '---\nstatus: approved\n---\n' > "$S/specs/001-foo/spec.md"
printf -- '---\nstatus: approved\n---\n' > "$S/specs/001-foo/plan.md"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H"; assert_eq "0" "$?" "code edit allowed after approval"

# only spec approved, plan still draft -> blocked
printf -- '---\nstatus: draft\n---\n' > "$S/specs/001-foo/plan.md"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "blocked when plan not approved"

# --- trivial-change path: proportionality without a bypass -------------------
# A typo fix must not cost six artifacts and two approvals; a refactor must not
# ride the same door. See docs/design-notes/over-constraint-audit.md.
pg() { printf '{"cwd":"%s","tool_name":"Edit","tool_input":{"file_path":"%s/src/app.py","new_string":%s}}' "$S" "$S" "$(node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1")"; }

# the block message must advertise the door, or nobody finds it
out="$(pg 'x = 1' | node "$H" 2>&1 >/dev/null)"
echo "$out" | grep -qF ".specify/trivial" && pass "block message points at the trivial path" || fail "block should advertise the trivial path (got: $out)"

# declared reason + small edit -> allowed, and says so
printf 'fix typo in greet()\n' > "$S/.specify/trivial"
assert_eq "0" "$(pg 'x = 1' | node "$H" >/dev/null 2>&1; echo $?)" "small edit allowed with a declared reason"
out="$(pg 'x = 1' | node "$H" 2>&1 >/dev/null)"
echo "$out" | grep -qF "fix typo in greet()" && pass "allowed edit echoes the declared reason" || fail "should echo the reason (got: $out)"
echo "$out" | grep -qi "announce" && pass "trivial path demands the skip be announced" || fail "should demand announcing the skip (got: $out)"
pg 'x = 1' | node "$H" 2>/dev/null | grep -qF '"permissionDecision":"allow"' && pass "emits an explicit allow decision" || fail "should emit permissionDecision allow"

# an edit that is not actually small must NOT ride the trivial door
big="$(printf 'l%.0s\n' $(seq 1 25))"
assert_eq "2" "$(pg "$big" | node "$H" >/dev/null 2>&1; echo $?)" "25-line edit refused by the trivial path"
out="$(pg "$big" | node "$H" 2>&1 >/dev/null)"
echo "$out" | grep -qF "trivial limit" && pass "refusal explains the size limit" || fail "refusal should cite the limit (got: $out)"

# the door expires: a stale marker stops working
touch -d '2 hours ago' "$S/.specify/trivial" 2>/dev/null || touch -t 200001010000 "$S/.specify/trivial"
assert_eq "2" "$(pg 'x = 1' | node "$H" >/dev/null 2>&1; echo $?)" "stale trivial marker no longer opens the door"

# an empty marker is not a reason
: > "$S/.specify/trivial"
assert_eq "2" "$(pg 'x = 1' | node "$H" >/dev/null 2>&1; echo $?)" "empty marker does not open the door"

rm -rf "$S"
