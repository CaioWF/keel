SK="$HERE/../core/claude/skills"
for s in constitution-writer prd-writer spec-writer clarify plan-writer tasks-writer analyze; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
  assert_contains "$SK/$s/SKILL.md" "description:" "$s has description frontmatter"
done
