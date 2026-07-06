SK="$HERE/../core/claude/skills"
for s in brainstorming systematic-debugging using-git-worktrees dispatching-parallel-agents subagent-driven-development verification-before-completion test-driven-development receiving-code-review finishing-a-development-branch; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
done
# vendored skills must drop all superpowers cross-refs (Path A)
for s in receiving-code-review finishing-a-development-branch; do
  grep -qiF "superpowers:" "$SK/$s/SKILL.md" && fail "$s must drop superpowers cross-refs" || pass "$s has no superpowers cross-refs"
done
# wired into the chain + review flow
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "finishing-a-development-branch" "CLAUDE.md ends chain with finishing-a-development-branch"
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "receiving-code-review" "CLAUDE.md cites receiving-code-review"
# finishing uses keel gates, not a hardcoded test runner
assert_contains "$SK/finishing-a-development-branch/SKILL.md" "run-gates.sh" "finishing verifies via run-gates"
# authoring-skills repo doc (writing-skills distilled)
assert_file "$HERE/../docs/authoring-skills.md" "authoring-skills repo doc exists"
# test-driven-development: behavior-not-implementation concept + required + companion
T="$SK/test-driven-development/SKILL.md"
assert_contains "$T" "Behavior, Not Implementation" "tdd has behavior-not-implementation section"
assert_contains "$T" "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST" "tdd states the Iron Law"
assert_contains "$T" "REQUIRED" "tdd marked required"
assert_file "$SK/test-driven-development/testing-anti-patterns.md" "tdd companion anti-patterns exists"
# TDD wired as a required step in the flow
assert_contains "$SK/implement-feature/SKILL.md" "test-driven-development" "implement-feature requires the tdd skill"
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "test-driven-development" "CLAUDE.md mandates tdd skill"
assert_contains "$HERE/../core/claude/CLAUDE.md.tmpl" "TDD is a REQUIRED step" "CLAUDE.md marks tdd required"
B="$SK/brainstorming/SKILL.md"
assert_contains "$B" "one question at a time" "brainstorming keeps one-question-at-a-time"
assert_contains "$B" "prd-writer"             "brainstorming hands off to prd-writer"
grep -qiF "writing-plans" "$B" && fail "brainstorming must drop superpowers writing-plans handoff" || pass "brainstorming drops writing-plans handoff"
grep -qiF "superpowers:" "$B" && fail "brainstorming must drop superpowers cross-refs" || pass "brainstorming has no superpowers cross-refs"
D="$SK/dispatching-parallel-agents/SKILL.md"
assert_contains "$D" "Selective orchestration"   "dispatching has folded selective-orchestration rule"
assert_contains "$D" "Cost-aware model routing"  "dispatching has folded cost-routing rule"

# subagent-driven-development progressive-disclosure split (pilot): heavy detail
# lives in references/, the body links each so it loads on demand.
SDD="$SK/subagent-driven-development"
for r in dispatch-mechanics example-workflow troubleshooting; do
  assert_file "$SDD/references/$r.md" "SDD reference $r exists"
  assert_contains "$SDD/SKILL.md" "references/$r.md" "SDD body links reference $r"
done
# the moved sections must NOT remain duplicated in the body
grep -qF "## Constructing Reviewer Prompts" "$SDD/SKILL.md" && fail "SDD body still holds moved Constructing Reviewer Prompts" || pass "SDD body defers reviewer-prompt detail to reference"
grep -qF "## Example Workflow" "$SDD/SKILL.md" && fail "SDD body still holds moved Example Workflow" || pass "SDD body defers example workflow to reference"
