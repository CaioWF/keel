H="$HERE/../core/claude/hooks/okf-index.mjs"

# indexes a doc with `type:` frontmatter and emits the SessionStart shape
S="$(new_sandbox)"; mkdir -p "$S/specs/feat-x"
printf -- '---\ntype: table\nname: orders\ndescription: Customer orders fact table\n---\nRelaciona [[line-items]] e [[users]].\n' > "$S/specs/feat-x/orders.md"
OUT=$(printf '{"cwd":"%s"}' "$S" | node "$H")
echo "$OUT" | grep -qF "SessionStart" && pass "emits SessionStart additionalContext" || fail "missing hook output shape"
echo "$OUT" | grep -qF "orders" && pass "indexes a type: concept" || fail "should index orders"
echo "$OUT" | grep -qF "[table]" && pass "groups concept under its type" || fail "should group by type"
echo "$OUT" | grep -qF "line-items" && pass "captures [[links]]" || fail "should capture wiki-links"
echo "$OUT" | grep -qF "Customer orders fact table" && pass "includes description in output" || fail "should include description"
echo "$OUT" | grep -qF "orders (specs/feat-x/orders.md) — Customer orders fact table" && pass "formats description as \" — <desc>\"" || fail "should format description correctly"

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
echo "$OUT3" | grep -qF "docs/mrr.md) —" && fail "should not add em-dash when no description" || pass "omits description formatting when absent"

# no OKF docs anywhere -> empty output, exit 0
S2="$(new_sandbox)"; mkdir -p "$S2/docs"
printf -- '# just prose\n' > "$S2/docs/readme.md"
OUTE=$(printf '{"cwd":"%s"}' "$S2" | node "$H"); rc=$?
assert_eq "0" "$rc" "exits 0 when no OKF docs"
assert_eq "" "$OUTE" "no output when nothing has type: frontmatter"

rm -rf "$S" "$S2"

# test budget and overflow pointers: with KEEL_OKF_BUDGET=2, showing 3 concepts of same type
S3="$(new_sandbox)"; mkdir -p "$S3/docs"
printf -- '---\ntype: note\nname: doc-a\n---\nFirst note.\n' > "$S3/docs/a.md"
printf -- '---\ntype: note\nname: doc-b\n---\nSecond note.\n' > "$S3/docs/b.md"
printf -- '---\ntype: note\nname: doc-c\n---\nThird note.\n' > "$S3/docs/c.md"

# with budget=2, should report true total of 3, show 2 in detail, and have overflow pointer
OUT_BUDGET=$(printf '{"cwd":"%s"}' "$S3" | KEEL_OKF_BUDGET=2 node "$H")
echo "$OUT_BUDGET" | grep -qF "3 concept(s)" && pass "reports true total (3) even with BUDGET=2" || fail "header should report true total count"
echo "$OUT_BUDGET" | grep -qF "doc-a" && pass "shows first concept within budget" || fail "should show doc-a"
echo "$OUT_BUDGET" | grep -qF "doc-b" && pass "shows second concept within budget" || fail "should show doc-b"
echo "$OUT_BUDGET" | grep -qF "doc-c" && fail "should not show third concept beyond budget" || pass "does not show third concept beyond budget"
echo "$OUT_BUDGET" | grep -qF "more" && grep -qF "Read on demand" <<< "$OUT_BUDGET" && pass "shows overflow pointer for unshown concepts" || fail "should show overflow pointer with 'more' and 'Read on demand'"

# with default budget (60) and only 3 concepts, should NOT show overflow pointer
OUT_DEFAULT=$(printf '{"cwd":"%s"}' "$S3" | node "$H")
echo "$OUT_DEFAULT" | grep -qF "3 concept(s)" && pass "reports total 3 with default budget" || fail "should report 3 concepts"
echo "$OUT_DEFAULT" | grep -qF "doc-a" && pass "shows all concepts with default budget" || fail "should show all concepts"
echo "$OUT_DEFAULT" | grep -qF "doc-c" && pass "shows third concept with default budget" || fail "should show all concepts"
! echo "$OUT_DEFAULT" | grep -qF "Read on demand" && pass "no overflow pointer with default budget and only 3 concepts" || fail "should not show overflow pointer when all concepts fit in budget"

rm -rf "$S3"
