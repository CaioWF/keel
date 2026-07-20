H="$HERE/../core/claude/hooks/destructive-guard.mjs"

# Run the guard on a Bash command; capture stdout + exit code separately.
# Verdicts: exit 2 = BLOCK; exit 0 + "ask" in stdout = ASK; exit 0 + empty = ALLOW.
dg_out() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1")" | node "$H" 2>/dev/null; }
dg_code() { printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1")" | node "$H" >/dev/null 2>&1; echo $?; }
# assert a command is asked (exit 0, stdout mentions permissionDecision ask)
assert_ask() { case "$(dg_out "$1")" in *'"permissionDecision":"ask"'*) pass "$2";; *) fail "$2 (not asked)";; esac; }
assert_block() { assert_eq "2" "$(dg_code "$1")" "$2"; }
assert_allow() { assert_eq "0" "$(dg_code "$1")" "$2"; c="$(dg_out "$1")"; [ -z "$c" ] && pass "$2 (silent)" || fail "$2 (unexpected output: $c)"; }

# --- BLOCK: catastrophic / irreversible ---
assert_block "rm -rf /"                                 "rm -rf / blocked"
assert_block "rm -rf /*"                                "rm -rf /* blocked"
assert_block "rm -rf \$HOME"                            "rm -rf \$HOME blocked"
assert_block "rm -rf /etc"                              "rm -rf /etc blocked"
assert_block "sudo rm -rf /usr"                         "rm -rf /usr blocked"
assert_block "git push --force origin main"            "git force-push blocked"
assert_block "git push -f"                              "git push -f blocked"
assert_block "dropdb production"                        "dropdb blocked"
assert_block "psql -c 'DROP DATABASE app'"             "DROP DATABASE blocked"
assert_block "mongo --eval 'db.dropDatabase()'"        "dropDatabase() blocked"
assert_block "mkfs.ext4 /dev/sdb1"                      "mkfs blocked"
assert_block "wipefs -a /dev/sda"                       "wipefs blocked"
assert_block "dd if=/dev/zero of=/dev/sda bs=1M"       "dd to disk blocked"
assert_block "cat img > /dev/sdb"                       "redirect to disk blocked"
assert_block "terraform destroy -auto-approve"         "terraform destroy blocked"
# block wins even when chained after a safe command
assert_block "echo hi && git push --force"             "block wins in a chain"

# --- ASK: destructive but routinely legit ---
assert_ask "rm -rf /data"                              "rm -rf /data asked"
assert_ask "rm -rf ./mydir"                            "rm -rf ./mydir asked"
assert_ask "rm -r src/old"                             "rm -r asked"
assert_ask "git reset --hard HEAD~3"                   "git reset --hard asked"
assert_ask "git reset --hard origin/main"             "git reset --hard remote asked"
assert_ask "git clean -fdx"                            "git clean -fdx asked"
assert_ask "git checkout -- ."                         "git checkout -- . asked"
assert_ask "git restore ."                             "git restore . asked"
assert_ask "git branch -D feature"                     "git branch -D asked"
assert_ask "git push --force-with-lease"              "force-with-lease asked (not blocked)"
assert_ask "git push origin --delete oldbranch"       "remote branch delete asked"
assert_ask "psql -c 'DROP TABLE users'"               "DROP TABLE asked"
assert_ask "psql -c 'TRUNCATE logs'"                  "TRUNCATE asked"
assert_ask "redis-cli FLUSHALL"                        "FLUSHALL asked"
assert_ask "mongo --eval 'db.users.drop()'"           "collection drop() asked"
assert_ask "mongo --eval 'db.users.deleteMany({})'"   "deleteMany({}) asked"
assert_ask "kubectl delete pod web-0"                  "kubectl delete asked"
assert_ask "helm uninstall myapp"                      "helm uninstall asked"

# --- ALLOW: safe carve-outs and ordinary commands ---
assert_allow "rm -rf node_modules"                     "rm -rf node_modules allowed"
assert_allow "rm -rf dist build"                       "rm -rf build dirs allowed"
assert_allow "rm -rf .next"                            "rm -rf .next allowed"
assert_allow "rm -rf /tmp/keel-test.XXX"               "rm -rf /tmp path allowed"
assert_allow "rm -rf coverage/.nyc_output"             "rm -rf coverage allowed"
assert_allow "rm -rf .git/sdd/feat"                    "rm -rf .git/sdd allowed"
assert_allow "rm file.txt"                             "non-recursive rm allowed"
assert_allow "git push origin main"                    "normal push allowed"
assert_allow "git commit -m 'wip'"                     "git commit allowed"
assert_allow "git reset --soft HEAD~1"                "git reset --soft allowed"
assert_allow "npm test"                                "npm test allowed"
assert_allow "ls -la && cat README.md"                 "ordinary chain allowed"

# --- registered in settings + shipped by bootstrap ---
assert_contains "$HERE/../core/claude/settings.hooks.json" "destructive-guard.mjs" "destructive-guard registered in settings"
SB="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB" >/dev/null 2>&1
assert_file "$SB/.claude/hooks/destructive-guard.mjs" "bootstrap ships destructive-guard hook"
assert_contains "$SB/.claude/settings.json" "destructive-guard.mjs" "bootstrap registers destructive-guard in target settings"
rm -rf "$SB"
