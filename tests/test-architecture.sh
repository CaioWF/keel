SK="$HERE/../core/claude/skills/architecture"
TPL="$HERE/../core/specify/templates"
CONST="$HERE/../core/specify/memory/constitution.md.tmpl"

# umbrella skill + frontmatter
assert_file "$SK/SKILL.md" "architecture skill exists"
assert_contains "$SK/SKILL.md" "name: architecture" "architecture has name frontmatter"

# 4 curated companions
for c in clean-architecture solid testing-strategy ddd-tactical; do
  assert_file "$SK/$c.md" "architecture companion $c exists"
done
# companions referenced by the umbrella skill
for c in clean-architecture solid testing-strategy ddd-tactical; do
  assert_contains "$SK/SKILL.md" "$c.md" "architecture skill indexes $c"
done
# testing-strategy references TDD (does not duplicate)
assert_contains "$SK/testing-strategy.md" "test-driven-development" "testing-strategy points to TDD skill"
# clean-architecture states the dependency rule
assert_contains "$SK/clean-architecture.md" "dependency rule" "clean-architecture states dependency rule"

# constitution carries the hard rules
assert_contains "$CONST" "Princípios de arquitetura" "constitution has architecture principles section"
assert_contains "$CONST" "Dependency rule" "constitution states the dependency rule"
assert_contains "$CONST" "agregado" "constitution states aggregate boundary"

# structure template
assert_file "$TPL/architecture-template.md" "architecture-template exists"
assert_contains "$TPL/architecture-template.md" "domain" "template names the domain layer"
assert_contains "$TPL/architecture-template.md" "realiza com seu idioma" "template has per-language realization note"

# design note recipe
assert_file "$HERE/../docs/design-notes/concepts-layer.md" "concepts-layer design note exists"

# CLAUDE.md cites the architecture skill
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "architecture" "CLAUDE.md cites architecture skill"
