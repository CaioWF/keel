SK="$HERE/../core/claude/skills/architecture"
TPL="$HERE/../core/specify/templates"
CONST="$HERE/../core/specify/memory/constitution.md.tmpl"

# umbrella skill + frontmatter
assert_file "$SK/SKILL.md" "architecture skill exists"
assert_contains "$SK/SKILL.md" "name: architecture" "architecture has name frontmatter"

# 4 curated companions. Five independent concepts = domain fan-out, so they live in
# references/ and load on demand (docs/design-notes/skill-anatomy-audit.md).
REF="$SK/references"
assert_nofile "$SK/clean-architecture.md" "architecture companions are not flat siblings"
for c in clean-architecture solid testing-strategy ddd-tactical; do
  assert_file "$REF/$c.md" "architecture companion $c exists under references/"
done
# companions referenced by the umbrella skill, as one-level-deep links
for c in clean-architecture solid testing-strategy ddd-tactical; do
  assert_contains "$SK/SKILL.md" "references/$c.md" "architecture skill links $c"
done
# minimalism companion (laziness ladder) exists, indexed, and stays distinct from simplify
assert_file "$REF/minimalism.md" "architecture companion minimalism exists"
assert_contains "$SK/SKILL.md" "references/minimalism.md" "architecture skill links minimalism"
assert_contains "$REF/minimalism.md" "laziness ladder" "minimalism states the laziness ladder"
assert_contains "$REF/minimalism.md" "simplify" "minimalism demarcates against simplify (pre vs post-write)"

# testing-strategy references TDD (does not duplicate)
assert_contains "$REF/testing-strategy.md" "test-driven-development" "testing-strategy points to TDD skill"
# clean-architecture states the dependency rule
assert_contains "$REF/clean-architecture.md" "dependency rule" "clean-architecture states dependency rule"

# constitution carries the hard rules
assert_contains "$CONST" "Architecture Principles" "constitution has architecture principles section"
assert_contains "$CONST" "Dependency rule" "constitution states the dependency rule"
assert_contains "$CONST" "Aggregate boundary" "constitution states aggregate boundary"

# structure template
assert_file "$TPL/architecture-template.md" "architecture-template exists"
assert_contains "$TPL/architecture-template.md" "domain" "template names the domain layer"
assert_contains "$TPL/architecture-template.md" "realizes it in its own idiom" "template has per-language realization note"

# design note recipe
assert_file "$HERE/../docs/design-notes/concepts-layer.md" "concepts-layer design note exists"
assert_file "$HERE/../docs/design-notes/verification-contract.md" "verification-contract design note exists"
assert_file "$HERE/../docs/design-notes/prose-slop-guard.md" "prose-slop-guard design note exists"
# The em-dash omission is deliberate and counter-intuitive; if the note stops saying so,
# someone "fixes" it later and the guard drowns in false positives.
assert_contains "$HERE/../docs/design-notes/prose-slop-guard.md" "em-dash" "slop-guard note records why em-dash is not a rule"
assert_file "$HERE/../docs/design-notes/context-engineering-audit.md" "context-engineering-audit design note exists"
assert_file "$HERE/../docs/design-notes/over-constraint-audit.md" "over-constraint-audit design note exists"
# The trivial path is a door in a default-deny gate: if the note stops explaining why it is
# bounded, announced, and expiring, the next edit widens it into a plain bypass.
assert_contains "$HERE/../docs/design-notes/over-constraint-audit.md" "declared door, not a bypass" "over-constraint note frames the trivial path as designed, not an exception"
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" ".specify/trivial" "CLAUDE.md documents the trivial-change path"

# CLAUDE.md cites the architecture skill
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "architecture" "CLAUDE.md cites architecture skill"
