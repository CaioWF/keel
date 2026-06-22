ADP="$HERE/adapters-check.mjs"
assert_file "$HERE/../lib/adapters.mjs" "adapters.mjs exists"
OUT=$(node "$ADP" 2>&1); rc=$?
assert_eq "0" "$rc" "adapters assertions pass"
echo "$OUT" | grep -qF "ADAPTERS OK" && pass "adapters-check reports OK" || fail "adapters-check failed: $OUT"
