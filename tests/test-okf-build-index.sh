SCRIPT="$HERE/../core/gates/okf-build-index.mjs"

# Test 1: build creates index.md with okf_version and concepts
S1="$(new_sandbox)"
mkdir -p "$S1/subdir"
cat > "$S1/concept1.md" <<'EOF'
---
type: design-note
title: First Concept
description: A test concept
---

# Content here
EOF

cat > "$S1/subdir/concept2.md" <<'EOF'
---
type: reference
title: Second Concept
---

# No description
EOF

( cd "$S1" && node "$SCRIPT" build "$S1" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "build exits 0"
assert_file "$S1/index.md" "index.md was created"
assert_contains "$S1/index.md" 'okf_version: "0.1"' "index.md has okf_version"
assert_contains "$S1/index.md" "# design-note" "index.md has design-note section"
assert_contains "$S1/index.md" "# reference" "index.md has reference section"
assert_contains "$S1/index.md" "* [First Concept](concept1.md) - A test concept" "concept1 bullet with description"
assert_contains "$S1/index.md" "* [Second Concept](subdir/concept2.md)" "concept2 bullet without description"

# Test 2: check after build exits 0 (idempotent)
( cd "$S1" && node "$SCRIPT" check "$S1" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check after build exits 0"

# Test 3: mutate concept description, check detects stale
cat > "$S1/concept1.md" <<'EOF'
---
type: design-note
title: First Concept
description: A different description
---

# Content here
EOF

( cd "$S1" && node "$SCRIPT" check "$S1" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "check detects stale index after mutation" || fail "check should detect stale index"

# Test 4: check on bundle with NO index.md exits 0 (no-op skip)
S2="$(new_sandbox)"
mkdir -p "$S2/subdir"
cat > "$S2/concept.md" <<'EOF'
---
type: spec
title: Some Spec
---
EOF

( cd "$S2" && node "$SCRIPT" check "$S2" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check on non-OKF bundle exits 0"

# Test 5: index.md with no frontmatter okf_version is treated as non-OKF
S3="$(new_sandbox)"
mkdir -p "$S3"
cat > "$S3/concept.md" <<'EOF'
---
type: spec
title: Some Spec
---
EOF
echo "# Not an OKF bundle" > "$S3/index.md"

( cd "$S3" && node "$SCRIPT" check "$S3" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check on index.md without okf_version exits 0 (skip)"

# Test 6: concepts sorted by type then path
S4="$(new_sandbox)"
mkdir -p "$S4/z" "$S4/a"
cat > "$S4/z/b.md" <<'EOF'
---
type: spec
title: ZB Spec
---
EOF
cat > "$S4/a/a.md" <<'EOF'
---
type: design-note
title: AA Note
---
EOF
cat > "$S4/z/a.md" <<'EOF'
---
type: spec
title: ZA Spec
---
EOF

( cd "$S4" && node "$SCRIPT" build "$S4" >/dev/null 2>&1 )
# Check sort order in output: design-note first (type), then specs in path order
content="$(cat "$S4/index.md")"
# design-note should come before spec
designpos=$(echo "$content" | grep -n "# design-note" | cut -d: -f1)
specpos=$(echo "$content" | grep -n "# spec" | cut -d: -f1)
[ "$designpos" -lt "$specpos" ] && pass "sections sorted by type" || fail "sections should be sorted by type"

# Test 7: skips index.md and log.md (reserved names)
S5="$(new_sandbox)"
cat > "$S5/concept.md" <<'EOF'
---
type: spec
title: My Concept
---
EOF
cat > "$S5/index.md" <<'EOF'
---
type: spec
title: Should Be Skipped
---
EOF
cat > "$S5/log.md" <<'EOF'
---
type: design-note
title: Should Also Be Skipped
---
EOF

( cd "$S5" && node "$SCRIPT" build "$S5" >/dev/null 2>&1 )
output="$(cat "$S5/index.md")"
echo "$output" | grep -q "Should Be Skipped" && fail "index.md should be skipped" || pass "index.md skipped"
echo "$output" | grep -q "Should Also Be Skipped" && fail "log.md should be skipped" || pass "log.md skipped"
echo "$output" | grep -q "My Concept" && pass "regular concept included" || fail "regular concept should be included"

# Test 8: title fallback: title → name → path
S6="$(new_sandbox)"
cat > "$S6/unnamed.md" <<'EOF'
---
type: reference
---
EOF

( cd "$S6" && node "$SCRIPT" build "$S6" >/dev/null 2>&1 )
assert_contains "$S6/index.md" "[unnamed]" "fallback to filename (no extension)"

# Test 9: zero concepts still writes valid index.md
S7="$(new_sandbox)"
mkdir -p "$S7"
( cd "$S7" && node "$SCRIPT" build "$S7" >/dev/null 2>&1 )
assert_file "$S7/index.md" "index.md created even with zero concepts"
assert_contains "$S7/index.md" 'okf_version: "0.1"' "frontmatter present with zero concepts"

# Test 10: invalid subcommand exits 2
S8="$(new_sandbox)"
( cd "$S8" && node "$SCRIPT" invalid "$S8" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 2 ] && pass "invalid subcommand exits 2" || fail "invalid subcommand should exit 2, got $rc"

# Test 11: missing arguments exits 2
( node "$SCRIPT" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 2 ] && pass "missing args exits 2" || fail "missing args should exit 2"

# Test 12: check message format is correct
S9="$(new_sandbox)"
mkdir -p "$S9"
cat > "$S9/c.md" <<'EOF'
---
type: plan
title: My Plan
description: A plan
---
EOF

( cd "$S9" && node "$SCRIPT" build "$S9" >/dev/null 2>&1 )
output="$( cd "$S9" && node "$SCRIPT" check "$S9" 2>&1 )"
echo "$output" | grep -qF "✓ " && pass "check success has checkmark" || fail "check success should have checkmark"
