# Test install manifest: bootstrap always stamps .specify/keel.json, --status reports it.

MF_S="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$MF_S" >/dev/null

# 1. manifest always written (even with no --agent/--pack)
assert_file "$MF_S/.specify/keel.json" "bootstrap writes .specify/keel.json unconditionally"

# 2. keel_version comes from the VERSION file
MF_VER="$(head -n1 "$HERE/../VERSION" | tr -d '[:space:]')"
assert_eq "$MF_VER" "$(node -pe "require('$MF_S/.specify/keel.json').keel_version")" "manifest keel_version from VERSION file"

# 3. commit + timestamps + default agent present
assert_contains "$MF_S/.specify/keel.json" '"commit"'       "manifest records commit"
assert_contains "$MF_S/.specify/keel.json" '"installed_at"' "manifest records installed_at"
assert_contains "$MF_S/.specify/keel.json" '"updated_at"'   "manifest records updated_at"
assert_eq "claude" "$(node -pe "require('$MF_S/.specify/keel.json').agents.join(',')")" "manifest agents defaults to claude"

# 4. re-run preserves installed_at (idempotent), refreshes updated_at
MF_INST1="$(node -pe "require('$MF_S/.specify/keel.json').installed_at")"
sleep 0.01
bash "$HERE/../bootstrap.sh" --dir "$MF_S" >/dev/null
assert_eq "$MF_INST1" "$(node -pe "require('$MF_S/.specify/keel.json').installed_at")" "re-run preserves installed_at"

# 5. packs + extra agents are recorded
MF_S2="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$MF_S2" --agent=codex --pack=ship >/dev/null
assert_eq "claude,codex" "$(node -pe "require('$MF_S2/.specify/keel.json').agents.join(',')")" "manifest records extra agents"
assert_contains "$MF_S2/.specify/keel.json" '"ship"' "manifest records installed pack"

# 6. --status reports an installed project and exits 0
if bash "$HERE/../bootstrap.sh" --dir "$MF_S" --status >/dev/null 2>&1; then
  pass "--status exits 0 on installed project"
else
  fail "--status exits 0 on installed project"
fi

# 7. --status exits nonzero when no manifest exists
MF_EMPTY="$(new_sandbox)"
if bash "$HERE/../bootstrap.sh" --dir "$MF_EMPTY" --status >/dev/null 2>&1; then
  fail "--status exits nonzero when not installed"
else
  pass "--status exits nonzero when not installed"
fi

rm -rf "$MF_S" "$MF_S2" "$MF_EMPTY"
