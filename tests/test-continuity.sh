SK="$HERE/../core/claude/skills"
DOCS="$HERE/../core/docs"

# handoff skill
assert_file "$SK/handoff/SKILL.md" "handoff skill exists"
assert_contains "$SK/handoff/SKILL.md" "name: handoff" "handoff has name frontmatter"
assert_contains "$SK/handoff/SKILL.md" "docs/STATE.md" "handoff operates on STATE.md"
assert_contains "$SK/handoff/SKILL.md" "PAUSE" "handoff covers pause mode"
assert_contains "$SK/handoff/SKILL.md" "RESUME" "handoff covers resume mode"

# STATE template
assert_file "$DOCS/STATE.md" "STATE.md template exists"
assert_contains "$DOCS/STATE.md" "Em andamento / próximo passo" "STATE has next-step section"
assert_contains "$DOCS/STATE.md" "volátil" "STATE marked volatile"

# ADR scaffold
assert_file "$DOCS/architecture/adr/_template.md" "ADR template exists"
assert_file "$DOCS/architecture/adr/0001-record-architecture-decisions.md" "ADR-0001 seed exists"
assert_contains "$DOCS/architecture/adr/_template.md" "Consequências" "ADR template has consequences"

# CLAUDE.md wires continuity + SPEC_DEVIATION + doc gates
C="$HERE/../core/claude/CLAUDE.md.tmpl"
assert_contains "$C" "docs/STATE.md" "CLAUDE.md references STATE.md"
assert_contains "$C" "handoff" "CLAUDE.md references handoff skill"
assert_contains "$C" "adr/" "CLAUDE.md references ADRs"
assert_contains "$C" "SPEC_DEVIATION" "CLAUDE.md documents SPEC_DEVIATION marker"
assert_contains "$C" "eval-spec-fidelity" "CLAUDE.md documents the fidelity gate"
assert_contains "$C" "audit-structure" "CLAUDE.md documents the structure gate"
