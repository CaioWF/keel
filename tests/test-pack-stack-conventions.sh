# stack-conventions pack: implementation-time convention lenses (naming/postgres/ts)
# consulted BEFORE code via .specify/impl-conventions.txt. Sourced by run.sh (HERE +
# helpers provided by lib.sh).
SPACK="$HERE/../packs/stack-conventions"

# Pack ships an installer + the three convention skills with frontmatter, advisory.
assert_file "$SPACK/install.sh" "stack-conventions pack has installer"
for lens in naming-conventions postgres-conventions typescript-conventions; do
  assert_file "$SPACK/skills/$lens/SKILL.md" "stack-conventions ships $lens skill"
  assert_contains "$SPACK/skills/$lens/SKILL.md" "name: $lens" "$lens has name frontmatter"
  assert_contains "$SPACK/skills/$lens/SKILL.md" "makes no edits" "$lens is advisory (no edits)"
done

# Core ships the empty living registry, seeded (never force-clobbered).
assert_file "$HERE/../core/specify/impl-conventions.txt" "core ships impl-conventions registry"

# Installing the pack onto a bare target copies skills and registers lenses.
SB="$(new_sandbox)"
bash "$SPACK/install.sh" --dir "$SB" >/dev/null 2>&1
assert_file "$SB/.claude/skills/naming-conventions/SKILL.md" "pack install copies naming-conventions"
assert_file "$SB/.specify/impl-conventions.txt" "pack install seeds/writes registry"
for lens in naming-conventions postgres-conventions typescript-conventions; do
  assert_contains "$SB/.specify/impl-conventions.txt" "$lens" "registry gains $lens"
done

# Idempotent: re-running does not duplicate registry lines.
bash "$SPACK/install.sh" --dir "$SB" >/dev/null 2>&1
COUNT="$(grep -cx "naming-conventions" "$SB/.specify/impl-conventions.txt")"
assert_eq "1" "$COUNT" "pack install is idempotent (no duplicate lens lines)"
rm -rf "$SB"

# End-to-end via explicit --pack: core seeds the registry, pack appends to it.
SB2="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB2" --pack=stack-conventions >/dev/null 2>&1
assert_file "$SB2/.specify/impl-conventions.txt" "bootstrap --pack writes registry"
assert_contains "$SB2/.specify/impl-conventions.txt" "postgres-conventions" "registry has pack postgres-conventions"
assert_file "$SB2/.claude/skills/typescript-conventions/SKILL.md" "bootstrap --pack installs ts skill"
rm -rf "$SB2"

# Stack detection: a TS signal (tsconfig.json) auto-installs the pack without --pack.
SB3="$(new_sandbox)"
: > "$SB3/tsconfig.json"
bash "$HERE/../bootstrap.sh" --dir "$SB3" >/dev/null 2>&1
assert_contains "$SB3/.specify/impl-conventions.txt" "naming-conventions" "TS signal auto-installs stack-conventions"
rm -rf "$SB3"

# Stack detection: a Postgres/Prisma signal in package.json also triggers it.
SB4="$(new_sandbox)"
printf '{"dependencies":{"prisma":"^5"}}' > "$SB4/package.json"
bash "$HERE/../bootstrap.sh" --dir "$SB4" >/dev/null 2>&1
assert_contains "$SB4/.specify/impl-conventions.txt" "postgres-conventions" "Prisma signal auto-installs stack-conventions"
rm -rf "$SB4"

# No stack signal ⇒ pack NOT auto-installed; registry stays lens-free (header only).
SB5="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$SB5" >/dev/null 2>&1
if grep -qx "naming-conventions" "$SB5/.specify/impl-conventions.txt" 2>/dev/null; then
  fail "no stack signal keeps registry lens-free"
else
  pass "no stack signal keeps registry lens-free"
fi

# Living registry: --force must NOT wipe a pack-registered lens.
bash "$SPACK/install.sh" --dir "$SB5" >/dev/null 2>&1
bash "$HERE/../bootstrap.sh" --dir "$SB5" --force >/dev/null 2>&1
assert_contains "$SB5/.specify/impl-conventions.txt" "naming-conventions" "--force preserves registered lens (living registry)"
rm -rf "$SB5"
