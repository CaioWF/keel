#!/usr/bin/env bash
# architecture-gates pack — mechanical enforcement of the dependency rule.
# Installs one gate (dependency-rule) into .specify/gates/pack.d/, where run-gates.sh picks it
# up, plus a layer map at .specify/architecture.json that the project then owns. The reasoning
# stays in the agnostic core (skills/architecture/references/) — this pack is the check, not
# the explanation. Opt-in ONLY — never auto-detected by bootstrap: it writes config into the
# project and adds a gate that can fail a build, which is a delivery choice rather than a
# stack fact. Idempotent: safe to re-run.
#
# Usage: bash packs/architecture-gates/install.sh --dir <target> [--force]
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) TARGET="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "[keel:architecture-gates] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# The gate is pack-owned code: refresh it like any other keel file.
GATE_DIR="$TARGET/.specify/gates/pack.d"
mkdir -p "$GATE_DIR"
for f in "$SELF"/gates/*.mjs; do
  [ -e "$f" ] || continue
  dest="$GATE_DIR/$(basename "$f")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel:architecture-gates] =$dest"
  else
    cp "$f" "$dest"; echo "[keel:architecture-gates] +$dest"
  fi
  chmod +x "$dest" 2>/dev/null || true
done

# The layer map is the opposite: seeded once, never overwritten, not even under --force. It
# describes THIS project's tree, so refreshing it from the template would throw away the real
# layer names and re-point the gate at directories that may not exist.
CFG="$TARGET/.specify/architecture.json"
if [ -e "$CFG" ]; then
  echo "[keel:architecture-gates] =$CFG (seeded, kept)"
else
  cp "$SELF/templates/architecture.json" "$CFG"
  echo "[keel:architecture-gates] +$CFG"
  echo "[keel:architecture-gates] edit it to match your tree — the gate only knows the layers declared there"
fi

echo "[keel:architecture-gates] pack installed at $TARGET"
