EV="$HERE/../lib/emit-views.mjs"
assert_file "$EV" "emit-views.mjs exists"

# minimal canonical source: CLAUDE.md + one skill with a companion
S="$(new_sandbox)"
printf '# PROJECT\nsee .claude/skills/foo\n' > "$S/CLAUDE.md"
mkdir -p "$S/.claude/skills/foo"
printf -- '---\nname: foo\ndescription: does foo\n---\nbody\n' > "$S/.claude/skills/foo/SKILL.md"
printf '# companion\nx\n' > "$S/.claude/skills/foo/impl-prompt.md"

node "$EV" --dir "$S" --agents codex,cursor,copilot,gemini,windsurf --version test >/dev/null 2>&1
# instruction files for all 5
assert_file "$S/AGENTS.md" "emit: codex AGENTS.md"
assert_file "$S/.cursor/rules/sdd.mdc" "emit: cursor rules"
assert_file "$S/.github/copilot-instructions.md" "emit: copilot instructions"
assert_file "$S/GEMINI.md" "emit: gemini instructions"
assert_file "$S/.windsurf/rules/sdd.md" "emit: windsurf rules"
# skills as commands
assert_file "$S/.agents/skills/foo/SKILL.md" "emit: codex skill-dir SKILL.md"
assert_file "$S/.agents/skills/foo/impl-prompt.md" "emit: codex copies companion"
assert_file "$S/.cursor/commands/foo.md" "emit: cursor command"
assert_file "$S/.gemini/commands/foo.toml" "emit: gemini toml command"
assert_file "$S/.github/prompts/foo.prompt.md" "emit: copilot prompt"
assert_file "$S/.windsurf/workflows/foo.md" "emit: windsurf workflow"
# flat clients drop companion file but keep a pointer
assert_nofile "$S/.cursor/commands/impl-prompt.md" "emit: flat client does not emit companion file"
assert_contains "$S/.cursor/commands/foo.md" "companheiros" "emit: flat command carries companion pointer"
# advisory banner in instructions
assert_contains "$S/GEMINI.md" "advisory" "emit: instructions carry advisory banner"
# manifest
assert_file "$S/.specify/clients.json" "emit: manifest written"
assert_contains "$S/.specify/clients.json" "gemini" "emit: manifest lists gemini"
assert_contains "$S/.specify/clients.json" "claude" "emit: manifest always includes claude source"
rm -rf "$S"

# symlink safety: pre-existing AGENTS.md -> CLAUDE.md is replaced, CLAUDE.md untouched
S2="$(new_sandbox)"
printf '# PROJECT canonical\n' > "$S2/CLAUDE.md"
mkdir -p "$S2/.claude/skills"
ln -s CLAUDE.md "$S2/AGENTS.md"
node "$EV" --dir "$S2" --agents codex >/dev/null 2>&1
assert_contains "$S2/CLAUDE.md" "canonical" "emit: CLAUDE.md not clobbered through symlink"
[ -L "$S2/AGENTS.md" ] && fail "emit: AGENTS.md should no longer be a symlink" || pass "emit: AGENTS.md replaced as real file"
rm -rf "$S2"
