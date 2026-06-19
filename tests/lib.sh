#!/usr/bin/env bash
# Tiny assertion helpers for harness shell tests. No external deps.
TESTS_RUN=0
TESTS_FAILED=0

pass() { TESTS_RUN=$((TESTS_RUN+1)); echo "  ok: $1"; }
fail() { TESTS_RUN=$((TESTS_RUN+1)); TESTS_FAILED=$((TESTS_FAILED+1)); echo "  FAIL: $1" >&2; }

assert_eq() { # expected actual msg
  if [ "$1" = "$2" ]; then pass "$3"; else fail "$3 (expected '$1', got '$2')"; fi
}
assert_file() { [ -e "$1" ] && pass "$2" || fail "$2 (missing $1)"; }
assert_nofile() { [ ! -e "$1" ] && pass "$2" || fail "$2 (unexpected $1)"; }
assert_contains() { # file substring msg
  if grep -qF "$2" "$1" 2>/dev/null; then pass "$3"; else fail "$3 (no '$2' in $1)"; fi
}
new_sandbox() { mktemp -d "${TMPDIR:-/tmp}/harness-test.XXXXXX"; }
