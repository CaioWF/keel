PACK="$HERE/../packs/ui-review"

# Pack ships an installer + the two lens skills with frontmatter.
assert_file "$PACK/install.sh" "ui-review pack has installer"
for lens in perf-review a11y-review; do
  assert_file "$PACK/skills/$lens/SKILL.md" "ui-review ships $lens skill"
  assert_contains "$PACK/skills/$lens/SKILL.md" "name: $lens" "$lens has name frontmatter"
  assert_contains "$PACK/skills/$lens/SKILL.md" "NO edits" "$lens is read-only"
done

# Installing the pack onto a bare target copies skills and registers lenses.
SB="$(new_sandbox)"
bash "$PACK/install.sh" --dir "$SB" >/dev/null 2>&1
assert_file "$SB/.claude/skills/perf-review/SKILL.md" "pack install copies perf-review"
assert_file "$SB/.claude/skills/a11y-review/SKILL.md" "pack install copies a11y-review"
# perf-review ships the numeric budgets companion (adapted from agent-skills, MIT) + references it
assert_file "$SB/.claude/skills/perf-review/performance-budgets.md" "pack install copies perf budgets companion"
assert_contains "$PACK/skills/perf-review/performance-budgets.md" "addyosmani/agent-skills" "perf budgets attributes adapted source"
assert_contains "$PACK/skills/perf-review/SKILL.md" "performance-budgets.md" "perf-review references its budgets companion"
assert_file "$SB/.specify/review-lenses.txt" "pack install seeds/writes registry"
assert_contains "$SB/.specify/review-lenses.txt" "perf-review" "registry gains perf-review"
assert_contains "$SB/.specify/review-lenses.txt" "a11y-review" "registry gains a11y-review"

# Idempotent: re-running does not duplicate registry lines.
bash "$PACK/install.sh" --dir "$SB" >/dev/null 2>&1
COUNT="$(grep -cx "perf-review" "$SB/.specify/review-lenses.txt")"
assert_eq "1" "$COUNT" "pack install is idempotent (no duplicate lens lines)"
rm -rf "$SB"

# End-to-end: bootstrap --pack=ui-review installs core + pack, lenses land in
# the registry alongside the core-seeded agnostic ones.
SB2="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB2" --pack=ui-review >/dev/null 2>&1
assert_file "$SB2/.specify/review-lenses.txt" "bootstrap --pack writes registry"
assert_contains "$SB2/.specify/review-lenses.txt" "code-review" "registry keeps core code-review lens"
assert_contains "$SB2/.specify/review-lenses.txt" "a11y-review" "registry has pack a11y-review lens"
assert_file "$SB2/.claude/skills/a11y-review/SKILL.md" "bootstrap --pack installs a11y-review skill"

# Unknown pack fails loudly rather than silently no-op.
if bash "$HERE/../bootstrap.sh" --dir "$SB2" --pack=does-not-exist >/dev/null 2>&1; then
  fail "bootstrap rejects unknown pack"
else
  pass "bootstrap rejects unknown pack"
fi
rm -rf "$SB2"

# --- api-review pack: same contract as ui-review ---
APACK="$HERE/../packs/api-review"
assert_file "$APACK/install.sh" "api-review pack has installer"
for lens in api-contract migration-safety; do
  assert_file "$APACK/skills/$lens/SKILL.md" "api-review ships $lens skill"
  assert_contains "$APACK/skills/$lens/SKILL.md" "name: $lens" "$lens has name frontmatter"
  assert_contains "$APACK/skills/$lens/SKILL.md" "NO edits" "$lens is read-only"
done

# Two packs compose: installing both stacks their lenses into one registry.
SB3="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB3" --pack=ui-review,api-review >/dev/null 2>&1
REG3="$SB3/.specify/review-lenses.txt"
for lens in code-review security-review perf-review a11y-review api-contract migration-safety; do
  assert_contains "$REG3" "$lens" "composed registry has $lens"
done
assert_file "$SB3/.claude/skills/api-contract/SKILL.md" "composed install has api-contract skill"
# No duplicate core lines after composing packs.
CORECOUNT="$(grep -cx "code-review" "$REG3")"
assert_eq "1" "$CORECOUNT" "composed registry keeps core lens unduplicated"
rm -rf "$SB3"

# --- saas-security pack: SaaS-domain security review lens, same contract ---
SPACK="$HERE/../packs/saas-security"
assert_file "$SPACK/install.sh" "saas-security pack has installer"
assert_file "$SPACK/skills/saas-security/SKILL.md" "saas-security ships lens skill"
assert_contains "$SPACK/skills/saas-security/SKILL.md" "name: saas-security" "saas-security has name frontmatter"
assert_contains "$SPACK/skills/saas-security/SKILL.md" "NO edits" "saas-security is read-only"
assert_contains "$SPACK/skills/saas-security/SKILL.md" "Server-side enforcement" "saas-security checks server-side enforcement"

SB6="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB6" --pack=saas-security >/dev/null 2>&1
assert_contains "$SB6/.specify/review-lenses.txt" "saas-security" "bootstrap --pack registers saas-security lens"
assert_contains "$SB6/.specify/review-lenses.txt" "security-review" "registry keeps core security-review lens"
assert_file "$SB6/.claude/skills/saas-security/SKILL.md" "bootstrap --pack installs saas-security skill"
# Idempotent under re-install: no duplicate lens line.
bash "$SPACK/install.sh" --dir "$SB6" >/dev/null 2>&1
SCOUNT="$(grep -cx "saas-security" "$SB6/.specify/review-lenses.txt")"
assert_eq "1" "$SCOUNT" "saas-security install is idempotent (no duplicate lens line)"
rm -rf "$SB6"
