SK="$HERE/../core/claude/skills"
for s in brainstorming systematic-debugging using-git-worktrees dispatching-parallel-agents subagent-driven-development verification-before-completion; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
done
B="$SK/brainstorming/SKILL.md"
assert_contains "$B" "one question at a time" "brainstorming keeps one-question-at-a-time"
assert_contains "$B" "prd-writer"             "brainstorming hands off to prd-writer"
grep -qiF "writing-plans" "$B" && fail "brainstorming must drop superpowers writing-plans handoff" || pass "brainstorming drops writing-plans handoff"
grep -qiF "superpowers:" "$B" && fail "brainstorming must drop superpowers cross-refs" || pass "brainstorming has no superpowers cross-refs"
D="$SK/dispatching-parallel-agents/SKILL.md"
assert_contains "$D" "Selective orchestration"   "dispatching has folded selective-orchestration rule"
assert_contains "$D" "Cost-aware model routing"  "dispatching has folded cost-routing rule"
