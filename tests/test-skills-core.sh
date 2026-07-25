SK="$HERE/../core/claude/skills"
for s in constitution-writer product-writer prd-writer spec-writer clarify plan-writer tasks-writer analyze codebase-map; do
  assert_file "$SK/$s/SKILL.md" "$s skill exists"
  assert_contains "$SK/$s/SKILL.md" "name: $s" "$s has name frontmatter"
  assert_contains "$SK/$s/SKILL.md" "description:" "$s has description frontmatter"
done

# codebase-map produces the reusable structural artifact and plan-writer consults it.
assert_contains "$SK/codebase-map/SKILL.md" "docs/codebase-map.md" "codebase-map writes the map artifact"
assert_contains "$SK/plan-writer/SKILL.md" "codebase-map" "plan-writer grounds in codebase-map"

# Replicate-before-inventing discipline: plan-writer mandates it, analyze flags divergence.
assert_contains "$SK/plan-writer/SKILL.md" "Replicate before inventing" "plan-writer mandates pattern replication"
assert_contains "$SK/analyze/SKILL.md" "architecture divergence" "analyze flags unjustified pattern divergence"

# Interview discipline in clarify (adapted from mattpocock/skills `grilling`, MIT): the
# questioning phase must fact-check first, recommend, order by dependency, and refuse to
# hand off with an open branch. Dropping these turns clarify back into a flat question dump.
assert_contains "$SK/clarify/SKILL.md" "Fact-check before asking" "clarify verifies before asking"
assert_contains "$SK/clarify/SKILL.md" "Order by dependency" "clarify orders questions by dependency"
assert_contains "$SK/clarify/SKILL.md" "Carry a recommendation" "clarify recommends an answer per question"
assert_contains "$SK/clarify/SKILL.md" "branch left open" "clarify refuses to hand off with an open branch"
assert_contains "$SK/clarify/SKILL.md" "mattpocock/skills" "clarify attributes the adapted source"
# Prior-art scan feeds the questions but must not anchor them: research is input to a
# question, never an answer, and one question must probe NOT following the convention.
assert_contains "$SK/clarify/SKILL.md" "Scan prior art" "clarify scans prior art before asking"
assert_contains "$SK/clarify/SKILL.md" "input to a question, never an answer" "clarify forbids prior art as the answer"
assert_contains "$SK/clarify/SKILL.md" "Reserve a creative branch" "clarify reserves a non-conventional branch"

# Product layer: product-writer authors the once-per-project brief; the PRD references it
# instead of re-deriving product context (user/problem/north-star). Keeps features coherent.
assert_contains "$SK/product-writer/SKILL.md" "product.md" "product-writer writes the product brief"
assert_contains "$SK/product-writer/SKILL.md" "once per project" "product-writer is once-per-project"
assert_contains "$SK/prd-writer/SKILL.md" "product.md" "prd-writer references the product brief"

# Feature seams: the PRD states dependencies + what the feature consumes/exposes, so
# coupling surfaces at product time instead of being discovered during planning.
assert_contains "$SK/prd-writer/SKILL.md" "Dependencies & Interfaces" "prd-writer fills the seams section"
assert_contains "$SK/prd-writer/SKILL.md" "Consumes" "prd-writer names the feature's inputs"
assert_contains "$SK/prd-writer/SKILL.md" "Exposes" "prd-writer names what the feature exposes"

# Data-layer contract: plan-writer fills the conditional section when DB is touched.
assert_contains "$SK/plan-writer/SKILL.md" "Data Layer Contract" "plan-writer fills data-layer contract"

# Slice-vs-layer decomposition axis: plan-writer chooses it, tasks-writer honors it,
# implement-and-evaluate makes the partition/mode decision visible. This is what unlocks
# dispatch-parallel — an edit that drops the guidance silently kills parallelization.
assert_contains "$SK/plan-writer/SKILL.md" "decomposition axis" "plan-writer chooses slice-vs-layer axis"
assert_contains "$SK/plan-writer/SKILL.md" "Vertical slice" "plan-writer names the vertical-slice axis"
assert_contains "$SK/tasks-writer/SKILL.md" "decomposition axis" "tasks-writer honors the plan's axis"
assert_file "$SK/implement-and-evaluate/SKILL.md" "implement-and-evaluate skill exists"
assert_contains "$SK/implement-and-evaluate/SKILL.md" "validate-parallel-scope.mjs partition" "implement-and-evaluate runs the partition"
assert_contains "$SK/implement-and-evaluate/SKILL.md" "announce" "implement-and-evaluate announces mode + batch plan"

# Verification contract: tasks-writer authors it, analyze cross-checks it. Without the
# author-time step nothing ever writes contract.md and the evaluator falls back forever.
assert_contains "$SK/tasks-writer/SKILL.md" "contract-template.md" "tasks-writer consumes the contract template"
assert_contains "$SK/tasks-writer/SKILL.md" "contract.md" "tasks-writer outputs contract.md"
assert_contains "$SK/tasks-writer/SKILL.md" "PENDING" "tasks-writer leaves status to the evaluator"
assert_contains "$SK/analyze/SKILL.md" "contract.md" "analyze cross-checks the contract"

# Context handoffs (see docs/design-notes/context-engineering-audit.md). Each of these is a link
# the chain used to get from the session transcript — which a fresh-context dispatch does not have.
assert_contains "$SK/spec-writer/SKILL.md" "prd.md" "spec-writer reads the PRD it makes precise"
assert_contains "$SK/plan-writer/SKILL.md" "Dependencies & Interfaces" "plan-writer consumes the PRD's seams"
grep -qF "RF1" "$SK/spec-writer/SKILL.md" && fail "spec-writer must use the template's FR identifier, not RF" || pass "spec-writer numbers requirements FR1 like the template"
