#!/usr/bin/env bash
set -uo pipefail
DIR="${1:-$PWD}"; cd "$DIR"
FAILED=0; RAN=0

run_check() { # name command...
  local name="$1"; shift
  echo "[harness:gates] running $name"
  RAN=$((RAN+1))
  "$@" || { echo "[harness:gates] $name FAILED"; FAILED=$((FAILED+1)); }
}

has_npm_script() { # name
  [ -f package.json ] || return 1
  node "$(dirname "$0")/has-npm-script.mjs" "$1"
}
has_make_target() { # name
  [ -f Makefile ] || return 1
  grep -qE "^$1:" Makefile
}

# Doc-layer conformance gates (zero-dep node, run on every project — node is assumed
# available since bootstrap requires it). Auto-skip when their inputs are absent.
GATES_DIR="$(cd "$(dirname "$0")" && pwd)"
for g in audit-structure eval-spec-fidelity validate-mermaid; do
  [ -f "$GATES_DIR/$g.mjs" ] && run_check "doc:$g" node "$GATES_DIR/$g.mjs" "$DIR"
done

if [ -f package.json ]; then
  for s in lint test build; do has_npm_script "$s" && run_check "npm:$s" npm run "$s"; done
elif [ -f Makefile ]; then
  for t in lint test; do has_make_target "$t" && run_check "make:$t" make "$t"; done
fi

if [ "$RAN" -eq 0 ]; then echo "[harness:gates] no checks detected"; exit 0; fi
if [ "$FAILED" -ne 0 ]; then echo "[harness:gates] $FAILED gate(s) failed"; exit 1; fi
echo "[harness:gates] all gates passed"; exit 0
