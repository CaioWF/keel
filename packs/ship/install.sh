#!/usr/bin/env bash
# ship pack — opt-in lifecycle discipline for the phase after the SDD chain integrates.
# Currently ships one implementation-time convention lens: observability-and-instrumentation.
# It copies into .claude/skills and registers in .specify/impl-conventions.txt, which
# implement-feature applies while coding a critical path and the Definition-of-Done checks
# before finish. Opt-in ONLY — never auto-detected by bootstrap (deploy/observe is an
# explicit choice, not a stack signal). Idempotent: safe to re-run.
#
# Usage: bash packs/ship/install.sh --dir <target> [--force]
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "[keel:ship] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Copy the pack's skills (SKILL.md + companions) into the target's skill tree.
find "$SELF/skills" -type f | while read -r f; do
  rel="${f#"$SELF"/skills/}"
  dest="$TARGET/.claude/skills/$rel"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel:ship] =$dest"
  else
    cp "$f" "$dest"; echo "[keel:ship] +$dest"
  fi
done

# Register the implementation-time lens (dedup by exact line). Seed the registry with its
# header if core's copy is absent so the pack also works on a bare target.
REG="$TARGET/.specify/impl-conventions.txt"
mkdir -p "$(dirname "$REG")"
[ -f "$REG" ] || printf '%s\n' '# Implementation-convention lenses, one skill name per line.' > "$REG"
for lens in observability-and-instrumentation; do
  if grep -qxF "$lens" "$REG"; then
    echo "[keel:ship] =lens $lens already registered"
  else
    printf '%s\n' "$lens" >> "$REG"; echo "[keel:ship] +lens $lens"
  fi
done

echo "[keel:ship] pack installed at $TARGET"
