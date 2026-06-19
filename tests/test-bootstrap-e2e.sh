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
         .claude/settings.json CLAUDE.md AGENTS.md; do
  assert_file "$S/$f" "e2e: $f installed"
done
assert_contains "$S/.claude/settings.json" "phase-gate.mjs" "e2e: hook registered"
# TS detection line
S2="$(new_sandbox)"; echo '{}' > "$S2/package.json"; echo '{}' > "$S2/tsconfig.json"
OUT=$(bash "$HERE/../bootstrap.sh" --dir "$S2")
echo "$OUT" | grep -qF "TS project detected" && pass "e2e: TS detection fires" || fail "e2e: should detect TS"
# non-TS: no detection line
S3="$(new_sandbox)"
OUT3=$(bash "$HERE/../bootstrap.sh" --dir "$S3")
echo "$OUT3" | grep -qF "TS project detected" && fail "e2e: should NOT detect TS" || pass "e2e: no false TS detection"
rm -rf "$S" "$S2" "$S3"
