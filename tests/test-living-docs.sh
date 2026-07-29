# Living project docs (docs/design-notes/living-project-docs.md): CLAUDE.md carries
# marker blocks that hold project-learned facts (written by learn-session) and
# pack-contributed sections, and both survive a keel upgrade. Sourced by run.sh.
INJ="$HERE/../lib/inject-section.mjs"
SK="$HERE/../core/claude/skills"
C="$HERE/../core/claude/CLAUDE.md.tmpl"

# --- injector: upsert semantics ---
SB="$(new_sandbox)"
printf '# Doc\n\nbody\n' > "$SB/doc.md"
printf 'first content\n' > "$SB/content.md"
node "$INJ" set "$SB/doc.md" demo "$SB/content.md" >/dev/null
assert_contains "$SB/doc.md" "<!-- BEGIN:keel:demo -->" "set creates the block when absent"
assert_contains "$SB/doc.md" "first content" "set writes the content"
assert_contains "$SB/doc.md" "body" "set preserves the surrounding body"

printf 'second content\n' > "$SB/content2.md"
node "$INJ" set "$SB/doc.md" demo "$SB/content2.md" >/dev/null
COUNT="$(grep -cF "<!-- BEGIN:keel:demo -->" "$SB/doc.md")"
assert_eq "1" "$COUNT" "set replaces in place (no duplicate block)"
assert_contains "$SB/doc.md" "second content" "set overwrites stale block content"
if grep -qF "first content" "$SB/doc.md"; then fail "set drops the old block content"; else pass "set drops the old block content"; fi

# ids lists what a doc carries; an invalid id is rejected rather than injected raw.
IDS="$(node "$INJ" ids "$SB/doc.md")"
assert_eq "demo" "$IDS" "ids lists the block"
if node "$INJ" set "$SB/doc.md" "Bad Id" "$SB/content.md" >/dev/null 2>&1; then
  fail "invalid block id is rejected"
else
  pass "invalid block id is rejected"
fi

# --- injector: carry-over across a template refresh ---
printf '# Doc v2\n\nnew body\n\n<!-- BEGIN:keel:demo -->\nplaceholder\n<!-- END:keel:demo -->\n' > "$SB/fresh.md"
node "$INJ" carry-over "$SB/doc.md" "$SB/fresh.md" >/dev/null
assert_contains "$SB/fresh.md" "second content" "carry-over restores the project's block"
assert_contains "$SB/fresh.md" "new body" "carry-over keeps the refreshed body"
if grep -qF "placeholder" "$SB/fresh.md"; then fail "carry-over replaces the template placeholder"; else pass "carry-over replaces the template placeholder"; fi
rm -rf "$SB"

# --- template: the environment section core seeds (the category a bootstrapped project had nowhere to record) ---
assert_contains "$C" "## Environment" "CLAUDE.md template seeds an Environment section"
assert_contains "$C" "<!-- BEGIN:keel:environment -->" "Environment section is a marker block"
assert_contains "$C" "learn-session" "CLAUDE.md template wires the learning loop"
assert_contains "$C" "docs/gotchas.md" "CLAUDE.md template routes traps out of the always-loaded file"

# --- bootstrap: learned content survives --force ---
SB2="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB2" >/dev/null 2>&1
assert_contains "$SB2/CLAUDE.md" "## Environment" "bootstrap installs the Environment section"
# Simulate a session that learned how this project starts.
node - "$SB2/CLAUDE.md" <<'EOF'
import { readFileSync, writeFileSync } from "node:fs";
const f = process.argv[2];
const learned = "<!-- BEGIN:keel:environment -->\n- start: ./scripts/init.sh\n<!-- END:keel:environment -->";
writeFileSync(f, readFileSync(f, "utf8").replace(/<!-- BEGIN:keel:environment -->[\s\S]*?<!-- END:keel:environment -->/, learned));
EOF
bash "$HERE/../bootstrap.sh" --dir "$SB2" --force >/dev/null 2>&1
assert_contains "$SB2/CLAUDE.md" "./scripts/init.sh" "--force preserves the learned environment block"
assert_contains "$SB2/CLAUDE.md" "SDD Workflow" "--force still refreshes keel's core body"
COUNT2="$(grep -cF "<!-- BEGIN:keel:environment -->" "$SB2/CLAUDE.md")"
assert_eq "1" "$COUNT2" "--force leaves exactly one environment block"
rm -rf "$SB2"

# --- packs contribute their own section, per detected stack ---
assert_file "$HERE/../packs/stack-conventions/claude-section.md" "stack-conventions ships a CLAUDE.md section"
SB3="$(new_sandbox)"
: > "$SB3/tsconfig.json"
bash "$HERE/../bootstrap.sh" --dir "$SB3" >/dev/null 2>&1
assert_contains "$SB3/CLAUDE.md" "<!-- BEGIN:keel:stack-conventions -->" "detected pack injects its section"
assert_contains "$SB3/CLAUDE.md" "typescript-conventions" "pack section names its lenses"
bash "$HERE/../bootstrap.sh" --dir "$SB3" --force >/dev/null 2>&1
COUNT3="$(grep -cF "<!-- BEGIN:keel:stack-conventions -->" "$SB3/CLAUDE.md")"
assert_eq "1" "$COUNT3" "pack section is re-rendered in place, not duplicated"
rm -rf "$SB3"

# --- learn-session: the loop that keeps the blocks true ---
L="$SK/learn-session/SKILL.md"
assert_file "$L" "learn-session skill exists"
assert_contains "$L" "name: learn-session" "learn-session has name frontmatter"
assert_contains "$L" "keel:environment" "learn-session routes environment facts to the block"
assert_contains "$L" "docs/gotchas.md" "learn-session routes traps to the gotchas concept"
assert_contains "$L" "type: gotchas" "learn-session registers gotchas as an OKF concept"
assert_contains "$L" "okf-build-index" "learn-session refreshes the index for the freshness gate"
assert_contains "$L" "still be true next week" "learn-session applies a durability test"
assert_contains "$L" "before showing the diff" "learn-session proposes before writing"
assert_contains "$L" "Do not commit" "learn-session never commits"

# Wired at the two session boundaries the project already has.
assert_contains "$SK/handoff/SKILL.md" "learn-session" "handoff pause routes durable facts to learn-session"
assert_contains "$SK/finishing-a-development-branch/SKILL.md" "learn-session" "finishing captures what the feature taught"

# The split is the point: STATE stays volatile, CLAUDE.md/gotchas take the durable.
assert_contains "$L" "volatile" "learn-session states the STATE boundary"
