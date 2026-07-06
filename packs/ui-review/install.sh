#!/usr/bin/env bash
# ui-review pack — adds stack-specific review lenses (perf, a11y) to a keel
# install. Copies the lens skills into .claude/skills and registers them in
# .specify/review-lenses.txt so review-and-simplify fans them out alongside the
# agnostic core lenses. Idempotent: safe to re-run.
#
# Usage: bash packs/ui-review/install.sh --dir <target> [--force]
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "[keel:ui-review] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Copy the pack's lens skills into the target's skill tree.
find "$SELF/skills" -type f | while read -r f; do
  rel="${f#"$SELF"/skills/}"
  dest="$TARGET/.claude/skills/$rel"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel:ui-review] =$dest"
  else
    cp "$f" "$dest"; echo "[keel:ui-review] +$dest"
  fi
done

# Register the lenses (dedup by exact line). Seed the registry if core's copy is
# absent so the pack also works on a bare target.
REG="$TARGET/.specify/review-lenses.txt"
mkdir -p "$(dirname "$REG")"
[ -f "$REG" ] || printf '%s\n' code-review security-review > "$REG"
for lens in perf-review a11y-review; do
  if grep -qxF "$lens" "$REG"; then
    echo "[keel:ui-review] =lens $lens already registered"
  else
    printf '%s\n' "$lens" >> "$REG"; echo "[keel:ui-review] +lens $lens"
  fi
done

echo "[keel:ui-review] pack installed at $TARGET"
