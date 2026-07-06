SK="$HERE/../core/claude/skills"
for s in security-review simplify review-and-simplify; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
done
R="$SK/review-and-simplify/SKILL.md"
assert_contains "$R" "security-review" "review-and-simplify runs security-review lens"
assert_contains "$R" "code-review"     "review-and-simplify runs code-review lens"
assert_contains "$R" "simplify"        "review-and-simplify runs simplify"
assert_contains "$R" "parallel"        "review-and-simplify fans out in parallel"
assert_contains "$SK/simplify/SKILL.md" "preserve" "simplify preserves behavior"
assert_contains "$SK/security-review/SKILL.md" "allow-list" "security-review checks whitelist rule"
assert_contains "$HERE/../core/specify/templates/checklist-template.md" "Segurança" "checklist has security section"
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "review-and-simplify" "CLAUDE.md wires review-and-simplify"

# Lens registry: core seeds the agnostic lenses; orchestrator reads the file.
REG="$HERE/../core/specify/review-lenses.txt"
assert_file "$REG" "core seeds review-lenses registry"
assert_contains "$REG" "code-review" "registry seeds code-review lens"
assert_contains "$REG" "security-review" "registry seeds security-review lens"
assert_contains "$R" "review-lenses.txt" "review-and-simplify reads the lens registry"
