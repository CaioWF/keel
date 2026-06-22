# Full core install on an empty dir, asserting every core artifact lands.
S="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$S" >/dev/null
for f in .specify/templates/spec-template.md \
         .specify/gates/run-gates.sh \
         .specify/gates/has-npm-script.mjs \
         .claude/hooks/phase-gate.mjs .claude/hooks/precommit-gate.mjs \
         .claude/hooks/phase-sensor.mjs .claude/hooks/load-constitution.mjs \
         .claude/hooks/_lib.mjs \
         .claude/skills/spec-writer/SKILL.md \
         .claude/skills/implement-and-evaluate/SKILL.md \
         .claude/skills/handoff/SKILL.md \
         .specify/gates/audit-structure.mjs \
         .specify/gates/eval-spec-fidelity.mjs \
         .specify/gates/validate-mermaid.mjs \
         docs/STATE.md \
         docs/architecture/adr/_template.md \
         docs/architecture/adr/0001-record-architecture-decisions.md \
         .claude/settings.json CLAUDE.md AGENTS.md; do
  assert_file "$S/$f" "e2e: $f installed"
done
assert_contains "$S/.claude/settings.json" "phase-gate.mjs" "e2e: hook registered"
# the freshly-installed project passes its own doc-layer gates
( cd "$S" && bash .specify/gates/run-gates.sh >/dev/null 2>&1 ); assert_eq "0" "$?" "e2e: scaffold passes its own gates"
# TS detection line
S2="$(new_sandbox)"; echo '{}' > "$S2/package.json"; echo '{}' > "$S2/tsconfig.json"
OUT=$(bash "$HERE/../bootstrap.sh" --dir "$S2")
echo "$OUT" | grep -qF "TS project detected" && pass "e2e: TS detection fires" || fail "e2e: should detect TS"
# non-TS: no detection line
S3="$(new_sandbox)"
OUT3=$(bash "$HERE/../bootstrap.sh" --dir "$S3")
echo "$OUT3" | grep -qF "TS project detected" && fail "e2e: should NOT detect TS" || pass "e2e: no false TS detection"

# backward-compat: no --agent => Claude-only, no view dirs, AGENTS.md stays a symlink
assert_nofile "$S/.cursor" "e2e: no cursor view without --agent"
assert_nofile "$S/.gemini" "e2e: no gemini view without --agent"
assert_nofile "$S/.specify/clients.json" "e2e: no manifest without --agent"
[ -L "$S/AGENTS.md" ] && pass "e2e: AGENTS.md is symlink in claude-only install" || fail "e2e: AGENTS.md should be symlink without codex"

# --all: every client view lands, manifest lists all, scaffold still passes its gates
S4="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$S4" --all >/dev/null
for f in AGENTS.md .cursor/rules/sdd.mdc .github/copilot-instructions.md GEMINI.md \
         .windsurf/rules/sdd.md .agents/skills/brainstorming/SKILL.md \
         .gemini/commands/brainstorming.toml .specify/clients.json; do
  assert_file "$S4/$f" "e2e(--all): $f generated"
done
assert_contains "$S4/.specify/clients.json" "windsurf" "e2e(--all): manifest lists windsurf"
[ -L "$S4/AGENTS.md" ] && fail "e2e(--all): AGENTS.md should be real view (codex selected)" || pass "e2e(--all): AGENTS.md is real codex view"
( cd "$S4" && bash .specify/gates/run-gates.sh >/dev/null 2>&1 ); assert_eq "0" "$?" "e2e(--all): scaffold+views pass gates (derived dirs ignored)"
rm -rf "$S" "$S2" "$S3" "$S4"
