#!/usr/bin/env bash
# Test bootstrap.sh core functionality: copy + idempotency + symlink

SANDBOX="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
assert_file "$SANDBOX/.specify"                 "creates .specify/"
assert_file "$SANDBOX/.claude/skills"           "creates .claude/skills/"
assert_file "$SANDBOX/.claude/hooks"            "creates .claude/hooks/"
assert_file "$SANDBOX/CLAUDE.md"                "creates CLAUDE.md"
assert_file "$SANDBOX/AGENTS.md"                "creates AGENTS.md"
assert_eq "CLAUDE.md" "$(readlink "$SANDBOX/AGENTS.md")" "AGENTS.md symlinks to CLAUDE.md"

# idempotency: write a marker, re-run without --force, marker survives
echo "MINE" > "$SANDBOX/CLAUDE.md"
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
assert_contains "$SANDBOX/CLAUDE.md" "MINE"     "re-run preserves edited CLAUDE.md"

# --force overwrites
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" --force >/dev/null
grep -qF "MINE" "$SANDBOX/CLAUDE.md" && fail "--force should overwrite CLAUDE.md" || pass "--force overwrites CLAUDE.md"

rm -rf "$SANDBOX"
