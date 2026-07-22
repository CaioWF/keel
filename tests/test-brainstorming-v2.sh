# brainstorming v2 — durable template, binary depth dial, adversarial gate.
# Sourced fragment (no shebang/exit): run.sh provides $HERE + lib helpers.
ROOT="$HERE/.."

# ---- brainstorm-template.md ----
BT="$ROOT/core/specify/templates/brainstorm-template.md"
assert_file "$BT" "brainstorm-template exists"
assert_contains "$BT" "status: draft" "brainstorm-template has draft frontmatter"
assert_contains "$BT" "## Entendimento" "brainstorm-template has Entendimento"
assert_contains "$BT" "## Investigação" "brainstorm-template has Investigação"
assert_contains "$BT" "## Abordagens consideradas" "brainstorm-template has Abordagens consideradas"
assert_contains "$BT" "## Decisões em aberto" "brainstorm-template has Decisões em aberto"
assert_contains "$BT" "## Esboço da solução" "brainstorm-template has Esboço da solução"

# ---- brainstorming SKILL wiring ----
BS="$ROOT/core/claude/skills/brainstorming/SKILL.md"
assert_contains "$BS" "brainstorm-template.md" "brainstorming references the template"
assert_contains "$BS" "doubt-driven-development" "brainstorming invokes the adversarial gate"
assert_contains "$BS" "deep" "brainstorming names the deep dial mode"
assert_contains "$BS" "dispatching-parallel-agents" "brainstorming deep mode dispatches divergence"

# ---- chain doc ----
assert_contains "$ROOT/core/claude/CLAUDE.md.tmpl" "doubt-driven-development" "CLAUDE.md.tmpl notes the brainstorming adversarial gate"

# ---- bootstrap ships the template ----
SB="$(new_sandbox)"
bash "$ROOT/bootstrap.sh" --dir "$SB" >/dev/null 2>&1
assert_file "$SB/.specify/templates/brainstorm-template.md" "bootstrap ships brainstorm-template"
rm -rf "$SB"
