#!/usr/bin/env bash
# Test settings.json hook merge: additive, dedup by command, preserves user hooks

SANDBOX="$(new_sandbox)"
# pre-existing user settings with an unrelated hook
mkdir -p "$SANDBOX/.claude"
cat > "$SANDBOX/.claude/settings.json" <<'EOF'
{ "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "echo user-hook" } ] } ] } }
EOF
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
assert_contains "$SANDBOX/.claude/settings.json" "load-constitution.mjs" "merges load-constitution hook"
assert_contains "$SANDBOX/.claude/settings.json" "phase-gate.mjs"        "merges phase-gate hook"
assert_contains "$SANDBOX/.claude/settings.json" "echo user-hook"       "preserves pre-existing user hook"

# idempotency: re-run, count phase-gate occurrences stays 1
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
N=$(grep -cF "phase-gate.mjs" "$SANDBOX/.claude/settings.json")
assert_eq "1" "$N" "no duplicate phase-gate hook after re-run"

rm -rf "$SANDBOX"
