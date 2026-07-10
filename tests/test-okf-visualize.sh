V="$HERE/../core/gates/okf-visualize.mjs"

assert_file "$V" "okf-visualize gate exists"

# Test 1: empty bundle (zero concepts) - should still emit valid HTML
S1="$(new_sandbox)"
mkdir -p "$S1/bundle"
node "$V" "$S1/bundle" --out "$S1/bundle/graph.html" > "$S1/out.txt" 2>&1
assert_eq "0" "$?" "empty bundle exits 0"
assert_file "$S1/bundle/graph.html" "empty bundle creates HTML output"
! grep -q 'https\?://' "$S1/bundle/graph.html"
pass "empty bundle HTML has no external URLs"

# Test 2: bundle with typed concepts and links
S2="$(new_sandbox)"
mkdir -p "$S2/concepts"

cat > "$S2/concepts/skill-auth.md" <<'EOF'
---
type: skill
title: Authentication
description: Core authentication mechanisms
---

This skill implements login and JWT token handling.
See [protocol](protocol.md) for details.
EOF

cat > "$S2/concepts/protocol.md" <<'EOF'
---
type: protocol
title: OAuth Protocol
description: OAuth 2.0 flow definition
---

Defines the flow for [[skill-auth]].
EOF

cat > "$S2/concepts/util.md" <<'EOF'
---
type: utility
title: Utility Helpers
---

Helper functions used across the system.
EOF

node "$V" "$S2/concepts" --out "$S2/concepts/graph.html" > "$S2/out.txt" 2>&1
assert_eq "0" "$?" "bundle with concepts exits 0"
assert_file "$S2/concepts/graph.html" "bundle creates HTML output file"
assert_contains "$S2/out.txt" "✓ wrote" "script prints success message"

# Test 3: HTML contains concept titles
assert_contains "$S2/concepts/graph.html" "Authentication" "HTML contains skill-auth title"
assert_contains "$S2/concepts/graph.html" "OAuth Protocol" "HTML contains protocol title"
assert_contains "$S2/concepts/graph.html" "Utility Helpers" "HTML contains utility title"

# Test 4: HTML is self-contained (no external URLs)
! grep -q 'https\?://' "$S2/concepts/graph.html"
pass "generated HTML has no external URLs (no http/https)"

# Test 5: HTML embeds nodes in DATA
assert_contains "$S2/concepts/graph.html" 'nodes:' "HTML contains nodes array"
assert_contains "$S2/concepts/graph.html" 'skill-auth.md' "HTML embeds skill-auth node id"
assert_contains "$S2/concepts/graph.html" 'protocol.md' "HTML embeds protocol node id"

# Test 6: HTML embeds edges
assert_contains "$S2/concepts/graph.html" 'edges:' "HTML contains edges array"
grep -q '"source"' "$S2/concepts/graph.html"
pass "HTML edges have source/target properties"

# Test 7: Types are mapped to colors deterministically
assert_contains "$S2/concepts/graph.html" 'typeToColor:' "HTML contains type color mapping"
assert_contains "$S2/concepts/graph.html" 'skill' "HTML type mapping includes skill"
assert_contains "$S2/concepts/graph.html" '#' "HTML type mapping has hex colors"

# Test 8: default output file (bundleDir/okf-graph.html)
S3="$(new_sandbox)"
mkdir -p "$S3/data"
cat > "$S3/data/item.md" <<'EOF'
---
type: concept
title: Test Concept
---
Content here.
EOF
node "$V" "$S3/data" > "$S3/out.txt" 2>&1
assert_eq "0" "$?" "script exits 0 with default output file"
assert_file "$S3/data/okf-graph.html" "default output file created at bundleDir/okf-graph.html"
assert_contains "$S3/out.txt" "okf-graph.html" "success message names default output file"

# Test 9: skip reserved files (index.md, log.md)
S4="$(new_sandbox)"
mkdir -p "$S4/test"
cat > "$S4/test/index.md" <<'EOF'
---
type: index
title: Index
---
This should be skipped.
EOF
cat > "$S4/test/log.md" <<'EOF'
---
type: log
title: Log
---
This should be skipped.
EOF
cat > "$S4/test/concept.md" <<'EOF'
---
type: concept
title: Real Concept
---
This should be included.
EOF
node "$V" "$S4/test" --out "$S4/test/out.html" > "$S4/log.txt" 2>&1
assert_contains "$S4/log.txt" "1 nodes" "reserved files are excluded from count"
! grep -q 'index.md' "$S4/test/out.html"
pass "index.md is skipped from output"
! grep -q 'log.md' "$S4/test/out.html"
pass "log.md is skipped from output"
