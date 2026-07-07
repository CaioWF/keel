SK="$HERE/../core/claude/skills"
for s in constitution-writer prd-writer spec-writer clarify plan-writer tasks-writer analyze codebase-map; do
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

# Data-layer contract: plan-writer fills the conditional section when DB is touched.
assert_contains "$SK/plan-writer/SKILL.md" "Contrato da Camada de Dados" "plan-writer fills data-layer contract"
