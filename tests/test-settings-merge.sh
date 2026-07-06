#!/usr/bin/env bash
# Test settings.json hook merge: additive, dedup by command, preserves user hooks

SANDBOX="$(new_sandbox)"
# pre-existing user settings with an unrelated hook and an unrelated deny rule
mkdir -p "$SANDBOX/.claude"
cat > "$SANDBOX/.claude/settings.json" <<'EOF'
{ "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "echo user-hook" } ] } ] },
  "permissions": { "deny": [ "Read(**/my-secret.txt)" ] } }
EOF
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
assert_contains "$SANDBOX/.claude/settings.json" "load-constitution.mjs" "merges load-constitution hook"
assert_contains "$SANDBOX/.claude/settings.json" "phase-gate.mjs"        "merges phase-gate hook"
assert_contains "$SANDBOX/.claude/settings.json" "echo user-hook"       "preserves pre-existing user hook"

# native permission deny seeded, and user's own deny preserved
assert_contains "$SANDBOX/.claude/settings.json" "Read(**/.env)"          "seeds native deny for .env"
assert_contains "$SANDBOX/.claude/settings.json" "Read(**/id_rsa)"        "seeds native deny for id_rsa"
assert_contains "$SANDBOX/.claude/settings.json" "Read(**/my-secret.txt)" "preserves pre-existing user deny rule"

# idempotency: re-run, hook and deny rule counts stay 1
bash "$HERE/../bootstrap.sh" --dir "$SANDBOX" >/dev/null
N=$(grep -cF "phase-gate.mjs" "$SANDBOX/.claude/settings.json")
assert_eq "1" "$N" "no duplicate phase-gate hook after re-run"
D=$(grep -cF 'Read(**/.env)"' "$SANDBOX/.claude/settings.json")
assert_eq "1" "$D" "no duplicate .env deny rule after re-run"

rm -rf "$SANDBOX"
