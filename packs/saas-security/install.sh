#!/usr/bin/env bash
# saas-security pack — adds the SaaS-domain security review lens (saas-security) to a
# keel install. Copies the lens skill into .claude/skills and registers it in
# .specify/review-lenses.txt so review-and-simplify fans it out alongside the agnostic
# core lenses (code-review, security-review). Idempotent: safe to re-run.
#
# Usage: bash packs/saas-security/install.sh --dir <target> [--force]
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "[keel:saas-security] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Copy the pack's lens skill into the target's skill tree.
find "$SELF/skills" -type f | while read -r f; do
  rel="${f#"$SELF"/skills/}"
  dest="$TARGET/.claude/skills/$rel"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel:saas-security] =$dest"
  else
    cp "$f" "$dest"; echo "[keel:saas-security] +$dest"
  fi
done

# Register the lens (dedup by exact line). Seed the registry if core's copy is
# absent so the pack also works on a bare target.
REG="$TARGET/.specify/review-lenses.txt"
mkdir -p "$(dirname "$REG")"
[ -f "$REG" ] || printf '%s\n' code-review security-review > "$REG"
for lens in saas-security; do
  if grep -qxF "$lens" "$REG"; then
    echo "[keel:saas-security] =lens $lens already registered"
  else
    printf '%s\n' "$lens" >> "$REG"; echo "[keel:saas-security] +lens $lens"
  fi
done

echo "[keel:saas-security] pack installed at $TARGET"
