#!/usr/bin/env bash
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --dir) TARGET="$2"; shift 2 ;;
    *) echo "[harness] unknown arg: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$TARGET"

# copy_file <src> <dest>
copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[harness] =$dest"; return 0
  fi
  cp "$src" "$dest"; echo "[harness] +$dest"
}
# copy_tree <srcdir> <destdir>
copy_tree() {
  local srcdir="$1" destdir="$2"
  [ -d "$srcdir" ] || return 0
  find "$srcdir" -type f | while read -r f; do
    local rel="${f#"$srcdir"/}"
    copy_file "$f" "$destdir/$rel"
  done
}

copy_tree "$SELF/core/specify"       "$TARGET/.specify"
copy_tree "$SELF/core/gates"         "$TARGET/.specify/gates"
copy_tree "$SELF/core/claude/skills" "$TARGET/.claude/skills"
copy_tree "$SELF/core/claude/hooks"  "$TARGET/.claude/hooks"
mkdir -p "$TARGET/.claude/skills" "$TARGET/.claude/hooks"
chmod +x "$TARGET/.claude/hooks/"*.mjs 2>/dev/null || true
copy_file "$SELF/core/claude/CLAUDE.md.tmpl" "$TARGET/CLAUDE.md"

# AGENTS.md -> CLAUDE.md (relative symlink), created only if absent or --force
if [ ! -e "$TARGET/AGENTS.md" ] || [ "$FORCE" -eq 1 ]; then
  ln -sf "CLAUDE.md" "$TARGET/AGENTS.md"; echo "[harness] +$TARGET/AGENTS.md"
else
  echo "[harness] =$TARGET/AGENTS.md"
fi

# Merge harness hook registrations into target settings.json (additive, dedup by command).
SETTINGS="$TARGET/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
node "$SELF/lib/merge-settings.mjs" "$SETTINGS" "$SELF/core/claude/settings.hooks.json"
echo "[harness] =merged hooks into $SETTINGS"

# Stack detection -> optional pack dispatch (runs after core install).
if [ -f "$TARGET/package.json" ] && [ -f "$TARGET/tsconfig.json" ]; then
  echo "[harness] TS project detected — ts-clean-arch pack"
  # The TS pack ships in a later plan (Plan 2); absent in core, so this is a
  # no-op until then. Detection still prints so the seam is observable.
  PACK="$SELF/packs/ts-clean-arch/install.sh"
  if [ -f "$PACK" ]; then
    if [ "$FORCE" -eq 1 ]; then bash "$PACK" --dir "$TARGET" --force; else bash "$PACK" --dir "$TARGET"; fi
  fi
fi

echo "[harness] core installed at $TARGET"
