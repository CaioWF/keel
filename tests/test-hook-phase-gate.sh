H="$HERE/../core/claude/hooks/phase-gate.mjs"
S="$(new_sandbox)"; mkdir -p "$S/specs/001-foo" "$S/src" "$S/.specify"; echo "001-foo" > "$S/.specify/state"

# editing a spec artifact is always allowed
printf '{"cwd":"%s","tool_input":{"file_path":"%s/specs/001-foo/spec.md"}}' "$S" "$S" | node "$H"; assert_eq "0" "$?" "editing spec artifact allowed"

# editing code with no approved spec/plan -> blocked (exit 2)
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "code edit blocked without approval"

# a nested dir coincidentally named docs/specs must NOT escape the gate
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/docs/util.js"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "nested src/docs does not bypass gate"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/specs/x.js"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "nested src/specs does not bypass gate"

# approve spec + plan -> allowed
printf -- '---\nstatus: approved\n---\n' > "$S/specs/001-foo/spec.md"
printf -- '---\nstatus: approved\n---\n' > "$S/specs/001-foo/plan.md"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H"; assert_eq "0" "$?" "code edit allowed after approval"

# only spec approved, plan still draft -> blocked
printf -- '---\nstatus: draft\n---\n' > "$S/specs/001-foo/plan.md"
printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/app.py"}}' "$S" "$S" | node "$H" 2>/dev/null; assert_eq "2" "$?" "blocked when plan not approved"

rm -rf "$S"
