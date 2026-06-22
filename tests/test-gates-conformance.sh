GATES="$HERE/../core/gates"

# ---- eval-spec-fidelity.mjs ----
EV="$GATES/eval-spec-fidelity.mjs"
assert_file "$EV" "eval-spec-fidelity.mjs exists"

# no specs/ -> exit 0
E1="$(new_sandbox)"
( node "$EV" "$E1" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: no specs exits 0"
rm -rf "$E1"

# spec with AC fully covered by tasks -> exit 0
E2="$(new_sandbox)"; mkdir -p "$E2/specs/0001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E2/specs/0001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n- [ ] T2 (AC-2)\n' > "$E2/specs/0001-x/tasks.md"
( node "$EV" "$E2" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: all AC covered exits 0"
rm -rf "$E2"

# spec with AC-2 uncovered by tasks -> exit 1
E3="$(new_sandbox)"; mkdir -p "$E3/specs/0001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E3/specs/0001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E3/specs/0001-x/tasks.md"
( node "$EV" "$E3" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "eval: uncovered AC fails" || fail "eval should fail on uncovered AC"
rm -rf "$E3"

# spec phase (AC present, no tasks.md yet) -> not enforced, exit 0
E4="$(new_sandbox)"; mkdir -p "$E4/specs/0001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E4/specs/0001-x/spec.md"
( node "$EV" "$E4" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: spec phase (no tasks.md) not enforced"
rm -rf "$E4"

# SPEC_DEVIATION counted in output
E5="$(new_sandbox)"; mkdir -p "$E5/specs/0001-x" "$E5/src"
printf '# spec\nAC-1: a\n' > "$E5/specs/0001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E5/specs/0001-x/tasks.md"
printf '// SPEC_DEVIATION: skipped AC-9 for now\nconst x=1; // AC-1\n' > "$E5/src/a.mjs"
out="$(node "$EV" "$E5" 2>&1)"
echo "$out" | grep -qF "SPEC_DEVIATION abertos no código: 1" && pass "eval: counts SPEC_DEVIATION" || fail "eval should count SPEC_DEVIATION (got: $out)"
rm -rf "$E5"

# ---- audit-structure.mjs ----
AU="$GATES/audit-structure.mjs"
assert_file "$AU" "audit-structure.mjs exists"

# clean project -> exit 0
A1="$(new_sandbox)"; mkdir -p "$A1/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\n# foo\n' > "$A1/.claude/skills/foo/SKILL.md"
( node "$AU" "$A1" >/dev/null 2>&1 ); assert_eq "0" "$?" "audit: clean project exits 0"
rm -rf "$A1"

# companion .md beside a SKILL.md (no frontmatter) does NOT fail
A1b="$(new_sandbox)"; mkdir -p "$A1b/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\n# foo\n' > "$A1b/.claude/skills/foo/SKILL.md"
printf '# prompt\nno frontmatter here\n' > "$A1b/.claude/skills/foo/prompt.md"
( node "$AU" "$A1b" >/dev/null 2>&1 ); assert_eq "0" "$?" "audit: companion .md beside SKILL.md is not a skill"
rm -rf "$A1b"

# skill missing name frontmatter -> exit 1
A2="$(new_sandbox)"; mkdir -p "$A2/.claude/skills/foo"
printf -- '---\ndescription: does foo\n---\n# foo\n' > "$A2/.claude/skills/foo/SKILL.md"
( node "$AU" "$A2" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: skill missing name fails" || fail "audit should fail on skill missing name"
rm -rf "$A2"

# specs/NNNN-* without spec.md -> exit 1
A3="$(new_sandbox)"; mkdir -p "$A3/specs/0001-x"
( node "$AU" "$A3" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: spec dir without spec.md fails" || fail "audit should fail on missing spec.md"
rm -rf "$A3"

# broken relative link -> exit 1
A4="$(new_sandbox)"
printf '# doc\nsee [other](./nope.md)\n' > "$A4/README.md"
( node "$AU" "$A4" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: broken relative link fails" || fail "audit should fail on broken link"
rm -rf "$A4"

# ---- validate-mermaid.mjs ----
VM="$GATES/validate-mermaid.mjs"
assert_file "$VM" "validate-mermaid.mjs exists"

# valid flowchart -> exit 0
V1="$(new_sandbox)"
printf '# d\n\n```mermaid\nflowchart TD\n  A --> B\n```\n' > "$V1/d.md"
( node "$VM" "$V1" >/dev/null 2>&1 ); assert_eq "0" "$?" "mermaid: valid flowchart exits 0"
rm -rf "$V1"

# empty mermaid block -> exit 1
V2="$(new_sandbox)"
printf '# d\n\n```mermaid\n```\n' > "$V2/d.md"
( node "$VM" "$V2" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "mermaid: empty block fails" || fail "mermaid should fail on empty block"
rm -rf "$V2"

# unknown diagram type -> exit 1
V3="$(new_sandbox)"
printf '# d\n\n```mermaid\nbogusDiagram\n  A --> B\n```\n' > "$V3/d.md"
( node "$VM" "$V3" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "mermaid: unknown type fails" || fail "mermaid should fail on unknown type"
rm -rf "$V3"

# project with no mermaid -> exit 0
V4="$(new_sandbox)"; printf '# plain\n' > "$V4/d.md"
( node "$VM" "$V4" >/dev/null 2>&1 ); assert_eq "0" "$?" "mermaid: no blocks exits 0"
rm -rf "$V4"

# ---- run-gates.sh runs doc gates always (no package.json needed) ----
G="$GATES/run-gates.sh"
R1="$(new_sandbox)"
cp "$GATES"/*.mjs "$R1/" 2>/dev/null
cp "$G" "$R1/run-gates.sh"
printf '# doc\nsee [x](./missing.md)\n' > "$R1/README.md"
( cd "$R1" && bash run-gates.sh >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "run-gates: doc gate blocks on broken link with no package.json" || fail "run-gates should run doc gates always"
rm -rf "$R1"

# ---- templates carry the AC-N convention ----
assert_contains "$HERE/../core/specify/templates/spec-template.md" "AC-1" "spec-template uses AC-N convention"
assert_contains "$HERE/../core/specify/templates/tasks-template.md" "AC-" "tasks-template references AC-N"
