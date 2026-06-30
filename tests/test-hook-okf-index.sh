H="$HERE/../core/claude/hooks/okf-index.mjs"

# indexes a doc with `type:` frontmatter and emits the SessionStart shape
S="$(new_sandbox)"; mkdir -p "$S/specs/feat-x"
printf -- '---\ntype: table\nname: orders\n---\nRelaciona [[line-items]] e [[users]].\n' > "$S/specs/feat-x/orders.md"
OUT=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT" | grep -qF "SessionStart" && pass "emits SessionStart additionalContext" || fail "missing hook output shape"
echo "$OUT" | grep -qF "orders" && pass "indexes a type: concept" || fail "should index orders"
echo "$OUT" | grep -qF "[table]" && pass "groups concept under its type" || fail "should group by type"
echo "$OUT" | grep -qF "line-items" && pass "captures [[links]]" || fail "should capture wiki-links"

# ignores .md without frontmatter, and frontmatter without a type:
mkdir -p "$S/docs"
printf -- '# plain\nno frontmatter here.\n' > "$S/docs/plain.md"
printf -- '---\nname: notype\n---\nhas frontmatter but no type.\n' > "$S/docs/notype.md"
OUT2=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT2" | grep -qF "plain" && fail "should skip files without frontmatter" || pass "skips non-OKF files"
echo "$OUT2" | grep -qF "notype" && fail "should skip frontmatter lacking type:" || pass "skips frontmatter without type"

# multiple types are grouped separately; name falls back to path when absent
printf -- '---\ntype: metric\n---\nmrr without a name key.\n' > "$S/docs/mrr.md"
OUT3=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT3" | grep -qF "[metric]" && pass "groups a second type" || fail "should group metric type"
echo "$OUT3" | grep -qF "docs/mrr" && pass "falls back to path when no name/title" || fail "should use path as name fallback"

# no OKF docs anywhere -> empty output, exit 0
S2="$(new_sandbox)"; mkdir -p "$S2/docs"
printf -- '# just prose\n' > "$S2/docs/readme.md"
OUTE=$(printf '{"cwd":"%s"}' "$S2" | node "$H"); rc=$?
assert_eq "0" "$rc" "exits 0 when no OKF docs"
assert_eq "" "$OUTE" "no output when nothing has type: frontmatter"

rm -rf "$S" "$S2"
