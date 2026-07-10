SCRIPT="$HERE/../core/gates/okf-build-index.mjs"

# Test 1: Build creates recursive index.md files
# Root concept + subdir concept should create both root/index.md and subdir/index.md
S1="$(new_sandbox)"
mkdir -p "$S1/plans"
cat > "$S1/reference.md" <<'EOF'
---
type: reference
title: Root Reference
description: A root-level reference
---

# Content here
EOF

cat > "$S1/plans/feature-x.md" <<'EOF'
---
type: plan
title: Feature X Plan
description: Planning feature X
---

# Plan content
EOF

( cd "$S1" && node "$SCRIPT" build "$S1" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "build exits 0"
assert_file "$S1/index.md" "root index.md created"
assert_file "$S1/plans/index.md" "subdir index.md created"

# Test 2: Root index.md has okf_version frontmatter and Subdirectories section
assert_contains "$S1/index.md" 'okf_version: "0.1"' "root index.md has okf_version"
assert_contains "$S1/index.md" "# Subdirectories" "root index.md has Subdirectories section"
assert_contains "$S1/index.md" "[plans/]" "root index.md links to plans/"
assert_contains "$S1/index.md" "# reference" "root index.md has reference section with root concept"
assert_contains "$S1/index.md" "* [Root Reference]" "root concept in root index.md"

# Test 3: Subdir index.md has NO okf_version and only its own concepts
assert_contains "$S1/plans/index.md" "# plan" "plans index.md has plan section"
assert_contains "$S1/plans/index.md" "* [Feature X Plan]" "plans concept in plans index.md"
! grep -q "okf_version" "$S1/plans/index.md" && pass "plans index.md has NO okf_version" || fail "plans index.md should not have okf_version"

# Test 4: Root index.md should NOT contain subdir's concepts
! grep -q "Feature X Plan" "$S1/index.md" && pass "root index.md does not list subdir concepts" || fail "root should not list subdir concepts"
# Root index.md should only have its own reference section
content="$(cat "$S1/index.md")"
ref_count=$(echo "$content" | grep -c "# reference" || true)
plan_count=$(echo "$content" | grep -c "# plan" || true)
[ "$ref_count" -eq 1 ] && [ "$plan_count" -eq 0 ] && pass "root index has only root concepts" || fail "root should have only its own concepts"

# Test 5: check after build exits 0 (idempotent across tree)
( cd "$S1" && node "$SCRIPT" check "$S1" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check after build exits 0"

# Test 6: mutate concept in subdir, check detects stale in nested index
cat > "$S1/plans/feature-x.md" <<'EOF'
---
type: plan
title: Feature X Plan MODIFIED
description: Planning feature X modified
---

# Plan content
EOF

( cd "$S1" && node "$SCRIPT" check "$S1" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "check detects stale in nested index after mutation" || fail "check should detect stale nested index"

# Test 7: check on bundle with NO root index.md exits 0 (no-op skip)
S2="$(new_sandbox)"
mkdir -p "$S2/specs"
cat > "$S2/specs/api.md" <<'EOF'
---
type: spec
title: API Spec
description: REST API specification
---
EOF

( cd "$S2" && node "$SCRIPT" check "$S2" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check on non-OKF bundle exits 0"

# Test 8: index.md with no okf_version is treated as non-OKF (skip check)
S3="$(new_sandbox)"
mkdir -p "$S3/designs"
cat > "$S3/designs/pattern.md" <<'EOF'
---
type: design-note
title: Design Pattern
---
EOF
echo "# Manual Index" > "$S3/index.md"

( cd "$S3" && node "$SCRIPT" check "$S3" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "check on index.md without okf_version exits 0 (skip)"

# Test 9: multi-level hierarchy (root -> level1 -> level2)
S4="$(new_sandbox)"
mkdir -p "$S4/docs/deep/nested"
cat > "$S4/root.md" <<'EOF'
---
type: reference
title: Root
---
EOF
cat > "$S4/docs/mid.md" <<'EOF'
---
type: plan
title: Mid-level Plan
---
EOF
cat > "$S4/docs/deep/nested/item.md" <<'EOF'
---
type: spec
title: Nested Spec
---
EOF

( cd "$S4" && node "$SCRIPT" build "$S4" >/dev/null 2>&1 ); rc=$?
assert_eq "0" "$rc" "build multi-level exits 0"
assert_file "$S4/index.md" "root index.md exists"
assert_file "$S4/docs/index.md" "docs index.md exists"
assert_file "$S4/docs/deep/index.md" "docs/deep index.md exists"
assert_file "$S4/docs/deep/nested/index.md" "docs/deep/nested index.md exists"

# Verify hierarchy: only direct children listed in Subdirectories
assert_contains "$S4/index.md" "[docs/]" "root lists docs/"
! grep -q "\[deep/\]" "$S4/index.md" && pass "root does not list deep/" || fail "root should only list direct children"
assert_contains "$S4/docs/index.md" "[deep/]" "docs lists deep/"
assert_contains "$S4/docs/deep/index.md" "[nested/]" "deep lists nested/"

# Test 10: Reserved names (index.md, log.md) are skipped
S5="$(new_sandbox)"
cat > "$S5/real.md" <<'EOF'
---
type: spec
title: Real Concept
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
title: Log Should Be Skipped
---
EOF

( cd "$S5" && node "$SCRIPT" build "$S5" >/dev/null 2>&1 )
output="$(cat "$S5/index.md")"
echo "$output" | grep -q "Should Be Skipped" && fail "index.md should be skipped" || pass "index.md skipped"
echo "$output" | grep -q "Log Should Be Skipped" && fail "log.md should be skipped" || pass "log.md skipped"
echo "$output" | grep -q "Real Concept" && pass "regular concept included" || fail "regular concept should be included"

# Test 11: underscore-prefixed files (_template.md, _partial.md) are skipped
S6="$(new_sandbox)"
mkdir -p "$S6"
cat > "$S6/_template.md" <<'EOF'
---
type: adr
title: ADR Template
description: A template for ADRs
---
EOF
cat > "$S6/real-concept.md" <<'EOF'
---
type: spec
title: Real Concept
description: A real concept
---
EOF

( cd "$S6" && node "$SCRIPT" build "$S6" >/dev/null 2>&1 )
index_content="$(cat "$S6/index.md")"
echo "$index_content" | grep -q "_template" && fail "_template.md should be skipped" || pass "_template.md skipped in index"
echo "$index_content" | grep -q "ADR Template" && fail "_template.md should not appear in index" || pass "underscore files do not appear in index"
echo "$index_content" | grep -q "Real Concept" && pass "real-concept.md included in index" || fail "non-underscore files should be included"

# Test 12: concepts sorted by type then filename within each directory
S7="$(new_sandbox)"
mkdir -p "$S7/items"
cat > "$S7/items/z-spec.md" <<'EOF'
---
type: spec
title: Z Spec
---
EOF
cat > "$S7/items/a-spec.md" <<'EOF'
---
type: spec
title: A Spec
---
EOF
cat > "$S7/items/m-design.md" <<'EOF'
---
type: design-note
title: M Design
---
EOF

( cd "$S7" && node "$SCRIPT" build "$S7" >/dev/null 2>&1 )
content="$(cat "$S7/items/index.md")"
# design-note should come before spec
designpos=$(echo "$content" | grep -n "# design-note" | cut -d: -f1)
specpos=$(echo "$content" | grep -n "# spec" | cut -d: -f1)
[ "$designpos" -lt "$specpos" ] && pass "sections sorted by type" || fail "sections should be sorted by type"
# Within spec, a-spec should come before z-spec
apos=$(echo "$content" | grep -n "A Spec" | cut -d: -f1)
zpos=$(echo "$content" | grep -n "Z Spec" | cut -d: -f1)
[ "$apos" -lt "$zpos" ] && pass "concepts sorted by filename within type" || fail "concepts should be sorted by filename within type"

# Test 13: title fallback (title -> name -> filename)
S8="$(new_sandbox)"
cat > "$S8/unnamed.md" <<'EOF'
---
type: reference
---
EOF

( cd "$S8" && node "$SCRIPT" build "$S8" >/dev/null 2>&1 )
assert_contains "$S8/index.md" "[unnamed]" "fallback to filename (no extension)"

# Test 14: empty bundle (no concepts) still writes root index with frontmatter
S9="$(new_sandbox)"
mkdir -p "$S9"
( cd "$S9" && node "$SCRIPT" build "$S9" >/dev/null 2>&1 )
assert_file "$S9/index.md" "index.md created even with zero concepts"
assert_contains "$S9/index.md" 'okf_version: "0.1"' "frontmatter present with zero concepts"

# Test 15: invalid subcommand exits 2
S10="$(new_sandbox)"
( cd "$S10" && node "$SCRIPT" invalid "$S10" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 2 ] && pass "invalid subcommand exits 2" || fail "invalid subcommand should exit 2, got $rc"

# Test 16: missing arguments exits 2
( node "$SCRIPT" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 2 ] && pass "missing args exits 2" || fail "missing args should exit 2"

# Test 17: Subdirectories section shows correct concept counts
S11="$(new_sandbox)"
mkdir -p "$S11/cats/fur" "$S11/dogs"
cat > "$S11/cats/whiskers.md" <<'EOF'
---
type: pet
title: Whiskers
---
EOF
cat > "$S11/cats/fur/pattern.md" <<'EOF'
---
type: design-note
title: Fur Pattern
---
EOF
cat > "$S11/cats/fur/color.md" <<'EOF'
---
type: design-note
title: Fur Color
---
EOF
cat > "$S11/dogs/bark.md" <<'EOF'
---
type: reference
title: Bark Patterns
---
EOF

( cd "$S11" && node "$SCRIPT" build "$S11" >/dev/null 2>&1 )
# Root should list cats (3 concepts total in subtree) and dogs (1 concept)
assert_contains "$S11/index.md" "* [cats/](cats/index.md) - 3 concept(s)" "cats subdirectory shows 3 concepts"
assert_contains "$S11/index.md" "* [dogs/](dogs/index.md) - 1 concept(s)" "dogs subdirectory shows 1 concept"
# cats/index.md should list fur (2 concepts in subtree) and its own whiskers
assert_contains "$S11/cats/index.md" "[Whiskers]" "cats has whiskers concept"
assert_contains "$S11/cats/index.md" "* [fur/](fur/index.md) - 2 concept(s)" "cats lists fur with 2 concepts"

# Test 18: Subdirectories appear after concepts
S12="$(new_sandbox)"
mkdir -p "$S12/sub"
cat > "$S12/root.md" <<'EOF'
---
type: spec
title: Root Spec
---
EOF
cat > "$S12/sub/child.md" <<'EOF'
---
type: spec
title: Child Spec
---
EOF

( cd "$S12" && node "$SCRIPT" build "$S12" >/dev/null 2>&1 )
content="$(cat "$S12/index.md")"
# Subdirectories should come after the type sections
specline=$(echo "$content" | grep -n "# spec" | cut -d: -f1 | head -1)
subline=$(echo "$content" | grep -n "# Subdirectories" | cut -d: -f1)
[ "$specline" -lt "$subline" ] && pass "Subdirectories comes after type sections" || fail "Subdirectories should come after type sections"

# Test 19: Trailing newline consistency
S13="$(new_sandbox)"
mkdir -p "$S13/sub"
cat > "$S13/a.md" <<'EOF'
---
type: spec
title: A
---
EOF
cat > "$S13/sub/b.md" <<'EOF'
---
type: plan
title: B
---
EOF

( cd "$S13" && node "$SCRIPT" build "$S13" >/dev/null 2>&1 )
# Check that files end with exactly one newline
root_bytes=$(cat "$S13/index.md" | wc -c)
sub_bytes=$(cat "$S13/sub/index.md" | wc -c)
# Both should be non-empty
[ "$root_bytes" -gt 0 ] && [ "$sub_bytes" -gt 0 ] && pass "index files are not empty" || fail "index files should not be empty"
# Files should end with newline (last char is newline)
tail -c 1 "$S13/index.md" | od -An -tx1 | grep -q "0a" && pass "root index.md ends with newline" || fail "root index.md should end with newline"
tail -c 1 "$S13/sub/index.md" | od -An -tx1 | grep -q "0a" && pass "sub index.md ends with newline" || fail "sub index.md should end with newline"
# Should not have double newlines at end
! tail -c 2 "$S13/index.md" | od -An -tx1 | grep -q "0a 0a" && pass "root index.md has single trailing newline" || fail "root index.md should have exactly one trailing newline"
! tail -c 2 "$S13/sub/index.md" | od -An -tx1 | grep -q "0a 0a" && pass "sub index.md has single trailing newline" || fail "sub index.md should have exactly one trailing newline"
