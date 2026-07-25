H="$HERE/../core/claude/hooks/slop-guard.mjs"
assert_file "$H" "slop-guard.mjs exists"

# Drive the hook the way Claude Code does: a PostToolUse event on stdin.
# Verdict: exit 2 = warned (stderr goes to the agent); exit 0 + no output = silent.
sg_event() { # file content [tool]
  node -e 'process.stdout.write(JSON.stringify({tool_name:process.argv[3]||"Write",tool_input:{file_path:process.argv[1],content:process.argv[2],new_string:process.argv[2]}}))' "$1" "$2" "${3:-Write}"
}
sg_out()  { sg_event "$1" "$2" "${3:-Write}" | node "$H" 2>&1; }
sg_code() { sg_event "$1" "$2" "${3:-Write}" | node "$H" >/dev/null 2>&1; echo $?; }
assert_warn()   { assert_eq "2" "$(sg_code "$1" "$2" "${4:-Write}")" "$3"; }
assert_silent() { c="$(sg_code "$1" "$2" "${4:-Write}")"; o="$(sg_out "$1" "$2" "${4:-Write}")"; if [ "$c" = "0" ] && [ -z "$o" ]; then pass "$3"; else fail "$3 (exit $c, output: $o)"; fi; }

SLOP='# Doc

This is not just a parser, but a whole pipeline. It is worth noting that the module
stands as a testament to careful work, highlighting the importance of clarity.
'
CLEAN='# Doc

The parser reads tokens and returns an AST. It fails on unclosed strings; see
parse_string for the exact error text.
'

# --- warns past the threshold, silent under it ---
assert_warn   "/tmp/x.md" "$SLOP"  "markdown past the threshold warns"
assert_silent "/tmp/x.md" "$CLEAN" "plain markdown stays silent"
assert_silent "/tmp/x.md" "# Doc

It is worth noting that this stands as a testament to nothing.
" "two tells stay under the default threshold of 3"

# The warning names file, line, and rule — a bare complaint is not actionable.
out="$(sg_out "/tmp/x.md" "$SLOP")"
echo "$out" | grep -qF "/tmp/x.md:3" && pass "warning cites file:line" || fail "warning should cite file:line (got: $out)"
echo "$out" | grep -qF "not-just-x-but-y" && pass "warning names the rule" || fail "warning should name the rule (got: $out)"

# --- em-dash is deliberately NOT a tell (dead signal, worst false-positive source) ---
assert_silent "/tmp/x.md" "# Doc

The parser — which is fast — reads tokens — then returns — an AST — every time.
" "em-dash overuse alone does not warn"

# --- markdown: fenced code is not prose ---
assert_silent "/tmp/x.md" '# Doc

```js
// it is worth noting that this stands as a testament to highlighting the importance
const x = 1;
```
' "fenced code block is not scanned as prose"

# --- code files: comments are scanned, code is not ---
assert_warn "/tmp/x.ts" '// It is worth noting that this stands as a testament to good design,
// highlighting the importance of the intricate realm of parsers.
const x = 1;
' "slop in code comments warns"
assert_silent "/tmp/x.ts" 'const a = "it is worth noting";
const b = "stands as a testament";
const c = "highlighting the importance of the intricate realm";
' "slop-looking string literals in code do not warn"
assert_warn "/tmp/x.py" '# It is worth noting that this stands as a testament to good design,
# highlighting the importance of the intricate realm of parsers.
x = 1
' "python comments are scanned"

# --- files that carry no prose are skipped outright ---
assert_silent "/tmp/x.json" '{"note":"it is worth noting that this stands as a testament, highlighting the importance"}' "non-prose extension is skipped"
assert_silent "/tmp/x.md" "" "empty payload is skipped"

# --- heading rules: sections, not document titles; ornament, not signposts ---
assert_silent "/tmp/x.md" "# A Perfectly Ordinary Document Title
" "Title-Case H1 (document title) is not a tell"
out="$(sg_event "/tmp/x.md" "## When To Push Back On This
" | KEEL_SLOP_THRESHOLD=1 node "$H" 2>&1)"
echo "$out" | grep -qF "title-case-heading" && pass "Title-Case H2 (section) is a tell" || fail "should flag title-case section heading (got: $out)"
out="$(sg_event "/tmp/x.md" "## Handling The Reviewer ⚠
" | KEEL_SLOP_THRESHOLD=1 node "$H" 2>&1)"
echo "$out" | grep -qF "emoji-heading" && fail "warning sign in a heading is a signpost, not ornament" || pass "semantic ⚠ in heading is not an emoji tell"
out="$(sg_event "/tmp/x.md" "## Getting Started 🚀
" | KEEL_SLOP_THRESHOLD=1 node "$H" 2>&1)"
echo "$out" | grep -qF "emoji-heading" && pass "decorative emoji in heading is a tell" || fail "should flag decorative emoji heading (got: $out)"

# --- vocabulary needs two distinct words, so one repeated word cannot trip it ---
out="$(sg_event "/tmp/x.md" "The intricate design is intricate, and intricate again.
" | KEEL_SLOP_THRESHOLD=1 node "$H" 2>&1)"
echo "$out" | grep -qF "ai-vocabulary" && fail "one repeated word should not count as vocabulary slop" || pass "single repeated vocabulary word does not fire"

# --- knobs: threshold and off-switch ---
assert_eq "2" "$(sg_event "/tmp/x.md" "It is worth noting this.
" | KEEL_SLOP_THRESHOLD=1 node "$H" >/dev/null 2>&1; echo $?)" "KEEL_SLOP_THRESHOLD lowers the bar"
assert_eq "0" "$(sg_event "/tmp/x.md" "$SLOP" | KEEL_SLOP_OFF=1 node "$H" >/dev/null 2>&1; echo $?)" "KEEL_SLOP_OFF=1 silences the guard"

# --- Edit events carry the prose in new_string ---
assert_warn "/tmp/x.md" "$SLOP" "Edit payload is scanned too" "Edit"

# --- wiring ---
assert_contains "$HERE/../core/claude/settings.hooks.json" "slop-guard.mjs" "slop-guard registered in settings"
assert_contains "$HERE/../core/claude/settings.hooks.json" "PostToolUse" "registered on PostToolUse (cannot block, only report)"

# --- keel's own corpus must stay quiet: a guard that cries wolf gets turned off ---
noisy=0
for f in "$HERE"/../core/claude/skills/*/SKILL.md "$HERE"/../docs/design-notes/*.md "$HERE"/../core/specify/templates/*.md; do
  [ -e "$f" ] || continue
  rc="$(node -e 'const fs=require("fs");const p=process.argv[1];process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:p,content:fs.readFileSync(p,"utf8")}}))' "$f" | node "$H" >/dev/null 2>&1; echo $?)"
  [ "$rc" = "0" ] || { noisy=$((noisy+1)); echo "    noisy: $f"; }
done
assert_eq "0" "$noisy" "keel's own skills/notes/templates trip no warning"
