H="$HERE/../core/claude/hooks/load-constitution.mjs"
S="$(new_sandbox)"
mkdir -p "$S/.specify/memory"
echo "PRINCIPLE: ship small" > "$S/.specify/memory/constitution.md"
OUT=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT" | grep -qF "PRINCIPLE: ship small" && pass "injects constitution text" || fail "should inject constitution"
echo "$OUT" | grep -qF "SessionStart" && pass "emits SessionStart additionalContext" || fail "missing hook output shape"
# also injects docs/STATE.md (volatile work memory)
mkdir -p "$S/docs"
echo "NEXT STEP: implement AC-3" > "$S/docs/STATE.md"
OUTS=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUTS" | grep -qF "NEXT STEP: implement AC-3" && pass "injects STATE.md text" || fail "should inject STATE.md"
echo "$OUTS" | grep -qF "PRINCIPLE: ship small" && pass "still injects constitution alongside STATE" || fail "should keep constitution"

# STATE alone (no constitution) -> still injects, exit 0
S4="$(new_sandbox)"; mkdir -p "$S4/docs"
echo "STATE ONLY" > "$S4/docs/STATE.md"
OUT4=$(printf '{"cwd":"%s"}' "$S4" | node "$H"); rc4=$?
assert_eq "0" "$rc4" "exits 0 with STATE only"
echo "$OUT4" | grep -qF "STATE ONLY" && pass "injects STATE even without constitution" || fail "should inject STATE alone"

# absent constitution AND STATE -> empty output, exit 0
S2="$(new_sandbox)"
OUT2=$(printf '{"cwd":"%s"}' "$S2" | node "$H"); rc=$?
assert_eq "0" "$rc" "exits 0 when no base context"
assert_eq "" "$OUT2" "no output when neither constitution nor STATE"
rm -rf "$S" "$S2" "$S4"
