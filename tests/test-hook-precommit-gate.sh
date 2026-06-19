H="$HERE/../core/claude/hooks/precommit-gate.mjs"
S="$(new_sandbox)"; mkdir -p "$S/.specify/gates"
cp "$HERE/../core/gates/run-gates.sh" "$HERE/../core/gates/has-npm-script.mjs" "$S/.specify/gates/"
# non-commit command -> allowed (no gates even consulted)
printf '{"cwd":"%s","tool_input":{"command":"ls -la"}}' "$S" | node "$H"; assert_eq "0" "$?" "non-commit command passes through"
# git commit with failing gate -> blocked (npm test exits non-zero)
printf '{"scripts":{"test":"exit 1"}}' > "$S/package.json"
printf '{"cwd":"%s","tool_input":{"command":"git commit -m x"}}' "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "commit blocked when gates fail"
# git commit with passing gate -> allowed
printf '{"scripts":{"test":"true"}}' > "$S/package.json"
printf '{"cwd":"%s","tool_input":{"command":"git commit -m x"}}' "$S" | node "$H"; assert_eq "0" "$?" "commit allowed when gates pass"
# no gates installed -> do not block
S2="$(new_sandbox)"
printf '{"cwd":"%s","tool_input":{"command":"git commit -m x"}}' "$S2" | node "$H"; assert_eq "0" "$?" "no gates installed does not block commit"
rm -rf "$S" "$S2"
