H="$HERE/../core/claude/hooks/load-constitution.mjs"
S="$(new_sandbox)"
mkdir -p "$S/.specify/memory"
echo "PRINCIPLE: ship small" > "$S/.specify/memory/constitution.md"
OUT=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT" | grep -qF "PRINCIPLE: ship small" && pass "injects constitution text" || fail "should inject constitution"
echo "$OUT" | grep -qF "SessionStart" && pass "emits SessionStart additionalContext" || fail "missing hook output shape"
# absent constitution -> empty output, exit 0
S2="$(new_sandbox)"
OUT2=$(printf '{"cwd":"%s"}' "$S2" | node "$H"); rc=$?
assert_eq "0" "$rc" "exits 0 when no constitution"
assert_eq "" "$OUT2" "no output when no constitution"
rm -rf "$S" "$S2"
