H="$HERE/../core/claude/hooks/phase-sensor.mjs"
S="$(new_sandbox)"
mkdir -p "$S/specs/001-foo"
echo "x" > "$S/specs/001-foo/prd.md"           # has prd, no spec -> phase 'spec'
OUT=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT" | grep -qF "phase: spec" && pass "detects spec phase" || fail "should be spec phase"
echo "$OUT" | grep -qF "001-foo" && pass "names active feature" || fail "should name feature"
# explicit state file wins
mkdir -p "$S/.specify" "$S/specs/002-bar"; echo "002-bar" > "$S/.specify/state"
OUT2=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT2" | grep -qF "002-bar" && pass ".specify/state overrides active feature" || fail "state file should win"
rm -rf "$S"
