#!/usr/bin/env bash
# stack-conventions pack — adds implementation-time convention lenses
# (naming-conventions, postgres-conventions, typescript-conventions) to a keel
# install. Unlike the review packs, these are consulted BEFORE code is written:
# they copy into .claude/skills and register in .specify/impl-conventions.txt, which
# plan-writer reads to ground Decisões Técnicas and implement-feature applies while
# coding. Idempotent: safe to re-run.
#
# Usage: bash packs/stack-conventions/install.sh --dir <target> [--force]
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "[keel:stack-conventions] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Copy the pack's convention skills into the target's skill tree.
find "$SELF/skills" -type f | while read -r f; do
  rel="${f#"$SELF"/skills/}"
  dest="$TARGET/.claude/skills/$rel"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel:stack-conventions] =$dest"
  else
    cp "$f" "$dest"; echo "[keel:stack-conventions] +$dest"
  fi
done

# Register the convention lenses (dedup by exact line). Seed the registry with its
# header if core's copy is absent so the pack also works on a bare target.
REG="$TARGET/.specify/impl-conventions.txt"
mkdir -p "$(dirname "$REG")"
[ -f "$REG" ] || printf '%s\n' '# Implementation-convention lenses, one skill name per line.' > "$REG"
for lens in naming-conventions postgres-conventions typescript-conventions; do
  if grep -qxF "$lens" "$REG"; then
    echo "[keel:stack-conventions] =lens $lens already registered"
  else
    printf '%s\n' "$lens" >> "$REG"; echo "[keel:stack-conventions] +lens $lens"
  fi
done

echo "[keel:stack-conventions] pack installed at $TARGET"
