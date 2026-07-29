GATES="$HERE/../core/gates"

# ---- eval-spec-fidelity.mjs ----
EV="$GATES/eval-spec-fidelity.mjs"
assert_file "$EV" "eval-spec-fidelity.mjs exists"

# no specs/ -> exit 0
E1="$(new_sandbox)"
( node "$EV" "$E1" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: no specs exits 0"
rm -rf "$E1"

# spec with AC fully covered by tasks -> exit 0
E2="$(new_sandbox)"; mkdir -p "$E2/specs/001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E2/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n- [ ] T2 (AC-2)\n' > "$E2/specs/001-x/tasks.md"
( node "$EV" "$E2" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: all AC covered exits 0"
rm -rf "$E2"

# spec with AC-2 uncovered by tasks -> exit 1
E3="$(new_sandbox)"; mkdir -p "$E3/specs/001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E3/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E3/specs/001-x/tasks.md"
( node "$EV" "$E3" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "eval: uncovered AC fails" || fail "eval should fail on uncovered AC"
rm -rf "$E3"

# spec phase (AC present, no tasks.md yet) -> not enforced, exit 0
E4="$(new_sandbox)"; mkdir -p "$E4/specs/001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E4/specs/001-x/spec.md"
( node "$EV" "$E4" >/dev/null 2>&1 ); assert_eq "0" "$?" "eval: spec phase (no tasks.md) not enforced"
rm -rf "$E4"

# SPEC_DEVIATION counted in output
E5="$(new_sandbox)"; mkdir -p "$E5/specs/001-x" "$E5/src"
printf '# spec\nAC-1: a\n' > "$E5/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E5/specs/001-x/tasks.md"
printf '// SPEC_DEVIATION: skipped AC-9 for now\nconst x=1; // AC-1\n' > "$E5/src/a.mjs"
out="$(node "$EV" "$E5" 2>&1)"
echo "$out" | grep -qF "SPEC_DEVIATION open in code: 1" && pass "eval: counts SPEC_DEVIATION" || fail "eval should count SPEC_DEVIATION (got: $out)"
rm -rf "$E5"

# contract.md coverage is WARN-ONLY: it reports, it never blocks. A hard fail here would
# reject every feature authored before contracts existed.
E6="$(new_sandbox)"; mkdir -p "$E6/specs/001-x"
printf '# spec\nAC-1: a\n' > "$E6/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E6/specs/001-x/tasks.md"
out="$(node "$EV" "$E6" 2>&1)"; rc=$?
assert_eq "0" "$rc" "eval: missing contract.md does not block"
echo "$out" | grep -qF "no contract.md" && pass "eval: warns when contract.md is absent" || fail "eval should warn on absent contract.md (got: $out)"
rm -rf "$E6"

# contract present: declared AC counted, undeclared AC warned, PASS verdicts tallied
E7="$(new_sandbox)"; mkdir -p "$E7/specs/001-x"
printf '# spec\nAC-1: a\nAC-2: b\n' > "$E7/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n- [ ] T2 (AC-2)\n' > "$E7/specs/001-x/tasks.md"
printf '# contract\n\n## AC-1 - login\n- **proof**: tests/a.spec.ts:9\n- **status**: PASS (evaluator, 2026-07-25)\n' > "$E7/specs/001-x/contract.md"
out="$(node "$EV" "$E7" 2>&1)"; rc=$?
assert_eq "0" "$rc" "eval: undeclared AC in contract does not block"
echo "$out" | grep -qF "1/2 AC declared" && pass "eval: counts AC declared in contract" || fail "eval should count declared AC (got: $out)"
echo "$out" | grep -qF "no section in contract.md: AC-2" && pass "eval: names the AC missing a contract section" || fail "eval should name undeclared AC (got: $out)"
echo "$out" | grep -qF "1 marked PASS" && pass "eval: tallies PASS verdicts from the contract" || fail "eval should tally PASS verdicts (got: $out)"
rm -rf "$E7"

# reverse direction: a section for an AC the spec dropped/renumbered is a stale contract.
# This is how traceability docs rot, so the gate names it — still without blocking.
E7b="$(new_sandbox)"; mkdir -p "$E7b/specs/001-x"
printf '# spec\nAC-1: a\n' > "$E7b/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E7b/specs/001-x/tasks.md"
printf '# contract\n\n## AC-1 - login\n- **status**: PENDING\n\n## AC-7 - removed\n- **status**: PASS (evaluator, 2026-07-25)\n' > "$E7b/specs/001-x/contract.md"
out="$(node "$EV" "$E7b" 2>&1)"; rc=$?
assert_eq "0" "$rc" "eval: stale contract section does not block"
echo "$out" | grep -qF "spec no longer has (stale): AC-7" && pass "eval: warns on contract section for a dropped AC" || fail "eval should warn on stale contract section (got: $out)"
rm -rf "$E7b"

# a bare AC-N mention is NOT a declared proof — only a "## AC-N" section counts
E8="$(new_sandbox)"; mkdir -p "$E8/specs/001-x"
printf '# spec\nAC-1: a\n' > "$E8/specs/001-x/spec.md"
printf '# tasks\n- [ ] T1 (AC-1)\n' > "$E8/specs/001-x/tasks.md"
printf '# contract\n\nsomeday we will verify AC-1 properly\n' > "$E8/specs/001-x/contract.md"
out="$(node "$EV" "$E8" 2>&1)"
echo "$out" | grep -qF "no section in contract.md: AC-1" && pass "eval: bare AC-N mention is not a declared proof" || fail "eval should require a ## AC-N section (got: $out)"
rm -rf "$E8"

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
A3="$(new_sandbox)"; mkdir -p "$A3/specs/001-x"
( node "$AU" "$A3" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: spec dir without spec.md fails" || fail "audit should fail on missing spec.md"
rm -rf "$A3"

# --- Agent Skills conformance (platform limits are errors, doc guidance is warnings) ---
# Source: platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

# name outside the allowed charset -> exit 1 (the platform would reject the skill)
A4="$(new_sandbox)"; mkdir -p "$A4/.claude/skills/foo"
printf -- '---\nname: Foo_Bar\ndescription: does foo\n---\n# foo\n' > "$A4/.claude/skills/foo/SKILL.md"
( node "$AU" "$A4" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: skill name outside [a-z0-9-] fails" || fail "audit should fail on bad name charset"
rm -rf "$A4"

# name over 64 chars -> exit 1
A5="$(new_sandbox)"; LONG="$(printf 'a%.0s' $(seq 1 65))"; mkdir -p "$A5/.claude/skills/foo"
printf -- '---\nname: %s\ndescription: does foo\n---\n# foo\n' "$LONG" > "$A5/.claude/skills/foo/SKILL.md"
( node "$AU" "$A5" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: skill name over 64 chars fails" || fail "audit should fail on name length"
rm -rf "$A5"

# description over 1024 chars -> exit 1
A6="$(new_sandbox)"; BIG="$(printf 'x%.0s' $(seq 1 1025))"; mkdir -p "$A6/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: %s\n---\n# foo\n' "$BIG" > "$A6/.claude/skills/foo/SKILL.md"
( node "$AU" "$A6" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "audit: skill description over 1024 chars fails" || fail "audit should fail on description length"
rm -rf "$A6"

# SKILL.md body over 500 lines -> warns on stdout but still exits 0 (doc guidance, not a limit)
A7="$(new_sandbox)"; mkdir -p "$A7/.claude/skills/foo"
{ printf -- '---\nname: foo\ndescription: does foo\n---\n'; for i in $(seq 1 520); do echo "line $i"; done; } > "$A7/.claude/skills/foo/SKILL.md"
out="$(node "$AU" "$A7" 2>&1)"; rc=$?
assert_eq "0" "$rc" "audit: oversized SKILL.md body still exits 0 (warning, not error)"
case "$out" in *"500 lines"*) pass "audit: warns on SKILL.md body over 500 lines";; *) fail "audit should warn on body over 500 lines (got: $out)";; esac
rm -rf "$A7"

# companion over 100 lines without a table of contents -> warns, exits 0
A8="$(new_sandbox)"; mkdir -p "$A8/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\n# foo\n' > "$A8/.claude/skills/foo/SKILL.md"
{ echo "# big companion"; for i in $(seq 1 120); do echo "line $i"; done; } > "$A8/.claude/skills/foo/big.md"
out="$(node "$AU" "$A8" 2>&1)"; rc=$?
assert_eq "0" "$rc" "audit: companion without ToC still exits 0"
case "$out" in *"table of contents"*) pass "audit: warns on 100+ line companion with no ToC";; *) fail "audit should warn on companion missing ToC (got: $out)";; esac
rm -rf "$A8"

# same companion WITH a ToC -> no warning
A9="$(new_sandbox)"; mkdir -p "$A9/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\n# foo\n' > "$A9/.claude/skills/foo/SKILL.md"
{ echo "# big companion"; echo; echo "## Contents"; echo "- a"; for i in $(seq 1 120); do echo "line $i"; done; } > "$A9/.claude/skills/foo/big.md"
out="$(node "$AU" "$A9" 2>&1)"
case "$out" in *"table of contents"*) fail "audit should not warn when companion has a ToC";; *) pass "audit: companion with ToC is clean";; esac
rm -rf "$A9"

# prompt templates are copied verbatim into a dispatch, so a ToC would leak into the prompt -> exempt
A10="$(new_sandbox)"; mkdir -p "$A10/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\n# foo\n' > "$A10/.claude/skills/foo/SKILL.md"
{ echo "# reviewer brief"; for i in $(seq 1 120); do echo "line $i"; done; } > "$A10/.claude/skills/foo/task-reviewer-prompt.md"
out="$(node "$AU" "$A10" 2>&1)"
case "$out" in *"table of contents"*) fail "audit should exempt *-prompt.md from the ToC rule";; *) pass "audit: *-prompt.md exempt from ToC rule";; esac
rm -rf "$A10"

# keel's own corpus is clean under the new rules
( node "$AU" "$HERE/.." >/dev/null 2>&1 ); assert_eq "0" "$?" "audit: keel's own tree passes the conformance rules"

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
