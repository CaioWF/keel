SK="$HERE/../core/claude/skills"
for s in implement-feature evaluator fix-runner implement-and-evaluate code-review; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
done
# evaluator follows the verification contract instead of re-deriving it each loop, and its
# verdict is durable — it writes status back. Both halves matter: reading it closes the
# rework hole, writing it closes the "verification vanished with the session" hole.
EVAL="$SK/evaluator/SKILL.md"
assert_contains "$EVAL" "contract.md" "evaluator reads the verification contract"
assert_contains "$EVAL" "status:" "evaluator writes the status back"
assert_contains "$EVAL" "PASS (evaluator" "evaluator stamps the verdict with its source"
assert_contains "$EVAL" "Fall back" "evaluator degrades to spec.md when no contract exists"
assert_contains "$EVAL" "UNVERIFIED" "evaluator never records an unrun criterion as passing"
assert_contains "$EVAL" "stale" "evaluator reports a contract section for a dropped AC"
assert_contains "$EVAL" "contract drift" "evaluator refuses to re-stamp a criterion that changed"
assert_contains "$SK/implement-and-evaluate/SKILL.md" "contract.md" "final pass checks the contract is fully PASS"
# The implementer has to see the bar before it builds, not after the evaluator applies it.
assert_contains "$SK/implement-feature/SKILL.md" "contract.md" "implement-feature reads the contract it will be judged by"

C="$HERE/../core/claude/CLAUDE.md.tmpl"
assert_contains "$C" "SDD Workflow"  "CLAUDE.md has SDD Workflow section"
assert_contains "$C" "Quality Gates" "CLAUDE.md has Quality Gates section"
assert_contains "$C" "Code style"    "CLAUDE.md has Code style section"
assert_contains "$C" "Commits"       "CLAUDE.md has Commits section (folded rule)"
assert_contains "$C" "Security"      "CLAUDE.md has Security section (folded whitelist rule)"
