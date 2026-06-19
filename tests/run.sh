#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
for t in "$HERE"/test-*.sh; do
  [ -e "$t" ] || continue
  echo "== $(basename "$t") =="
  . "$t"
done
echo "---- $TESTS_RUN run, $TESTS_FAILED failed ----"
[ "$TESTS_FAILED" -eq 0 ]
