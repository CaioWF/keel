H="$HERE/../core/claude/hooks/secrets-guard.mjs"

# helper: emit a PreToolUse event and return the hook's exit code via assert
ev_read() { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1" | node "$H" 2>/dev/null; }
ev_bash() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | node "$H" 2>/dev/null; }

# --- Read: secrets blocked (exit 2) ---
ev_read "/proj/.env";               assert_eq "2" "$?" "Read .env blocked"
ev_read "/proj/.env.local";         assert_eq "2" "$?" "Read .env.local blocked"
ev_read "/proj/.env.production";    assert_eq "2" "$?" "Read .env.production blocked"
ev_read "/home/u/.ssh/id_rsa";      assert_eq "2" "$?" "Read id_rsa blocked"
ev_read "/proj/server.key";         assert_eq "2" "$?" "Read *.key blocked"
ev_read "/proj/cert.pem";           assert_eq "2" "$?" "Read *.pem blocked"
ev_read "/home/u/.aws/credentials"; assert_eq "2" "$?" "Read aws credentials blocked"
ev_read "/proj/.npmrc";             assert_eq "2" "$?" "Read .npmrc blocked"

# --- Read: carve-outs and normal files allowed (exit 0) ---
ev_read "/proj/.env.example";       assert_eq "0" "$?" ".env.example readable"
ev_read "/proj/.env.sample";        assert_eq "0" "$?" ".env.sample readable"
ev_read "/proj/.env.template";      assert_eq "0" "$?" ".env.template readable"
ev_read "/proj/src/index.ts";       assert_eq "0" "$?" "normal source readable"
ev_read "/proj/README.md";          assert_eq "0" "$?" "README readable"

# --- Grep on a secret path blocked ---
printf '{"tool_name":"Grep","tool_input":{"path":"/proj/.env"}}' | node "$H" 2>/dev/null
assert_eq "2" "$?" "Grep into .env blocked"

# --- Bash: reading verbs on secrets blocked ---
ev_bash "cat .env";                 assert_eq "2" "$?" "Bash cat .env blocked"
ev_bash "head -n5 .env.local";      assert_eq "2" "$?" "Bash head .env.local blocked"
ev_bash "grep KEY .env";            assert_eq "2" "$?" "Bash grep .env blocked"
ev_bash "base64 config/id_rsa";     assert_eq "2" "$?" "Bash base64 id_rsa blocked"
ev_bash "cat < .env";               assert_eq "2" "$?" "Bash input-redirect .env blocked"

# --- Bash: file management on secrets still allowed ---
ev_bash "rm .env";                  assert_eq "0" "$?" "Bash rm .env allowed"
ev_bash "cp .env.example .env";     assert_eq "0" "$?" "Bash cp example->env allowed"
ev_bash "echo FOO=1 >> .env";       assert_eq "0" "$?" "Bash append to .env allowed"
ev_bash "cat README.md";            assert_eq "0" "$?" "Bash cat normal file allowed"
ev_bash "cat .env.example";         assert_eq "0" "$?" "Bash cat .env.example allowed"

# --- registered in settings + shipped by bootstrap ---
assert_contains "$HERE/../core/claude/settings.hooks.json" "secrets-guard.mjs" "secrets-guard registered in settings"
SB="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB" >/dev/null 2>&1
assert_file "$SB/.claude/hooks/secrets-guard.mjs" "bootstrap ships secrets-guard hook"
assert_contains "$SB/.claude/settings.json" "secrets-guard.mjs" "bootstrap registers secrets-guard in target settings"
rm -rf "$SB"
