SK="$HERE/../core/claude/skills"
for s in implement-feature evaluator fix-runner implement-and-evaluate code-review; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
done
C="$HERE/../core/claude/CLAUDE.md.tmpl"
assert_contains "$C" "SDD Workflow"  "CLAUDE.md has SDD Workflow section"
assert_contains "$C" "Quality Gates" "CLAUDE.md has Quality Gates section"
assert_contains "$C" "Code style"    "CLAUDE.md has Code style section"
assert_contains "$C" "Commits"       "CLAUDE.md has Commits section (folded rule)"
assert_contains "$C" "Security"      "CLAUDE.md has Security section (folded whitelist rule)"
