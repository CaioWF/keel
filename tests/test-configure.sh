# Test --configure (interactive pack/agent selection), the TTY-gated banner, and the
# discovery print. The install path must stay non-interactive and byte-identical for
# captured callers — several asserts below exist to pin exactly that.

# ---- pure set arithmetic (sourced, no pty needed) ----
# Sourcing must not run the menu; that is what the BASH_SOURCE guard is for.
. "$HERE/../lib/configure.sh"
pass "sourcing lib/configure.sh does not run the menu"

keel_cfg_in_set "pack:ship" "pack:ship agent:codex" && pass "in_set finds a member" || fail "in_set finds a member"
keel_cfg_in_set "pack:shi" "pack:ship" && fail "in_set does not match a prefix" || pass "in_set does not match a prefix"

assert_eq "pack:a pack:b" "$(keel_cfg_toggle "pack:b" "pack:a")"        "toggle adds a missing item"
assert_eq "pack:a"        "$(keel_cfg_toggle "pack:b" "pack:a pack:b")" "toggle removes a present item"
assert_eq "pack:b"        "$(keel_cfg_toggle "pack:a" "pack:a pack:b")" "toggle removes from the head"
assert_eq ""              "$(keel_cfg_toggle "pack:a" "pack:a")"        "toggle empties a single-item set"

assert_eq "a b"   "$(keel_cfg_filter pack  "pack:a agent:x pack:b")"  "filter keeps only its kind"
assert_eq "x"     "$(keel_cfg_filter agent "pack:a agent:x pack:b")"  "filter strips the kind prefix"
assert_eq ""      "$(keel_cfg_filter agent "pack:a")"                 "filter yields empty when no match"
assert_eq "a,b,c" "$(keel_cfg_join "a b c")"                          "join comma-separates"
assert_eq ""      "$(keel_cfg_join "")"                               "join of empty is empty"

# Pack descriptions come from line 2 of each install.sh; the cut must land on a word
# boundary, because a mid-word chop in the menu reads as a bug.
CFG_DESC="$(keel_cfg_pack_desc "$HERE/../packs/ship/install.sh")"
[ -n "$CFG_DESC" ] && pass "pack description is read from install.sh" || fail "pack description is read from install.sh"
case "$CFG_DESC" in
  '#'*)       fail "pack description strips the comment marker" ;;
  *' pack '*) fail "pack description strips the name prefix" ;;
  *)          pass "pack description strips marker and name prefix" ;;
esac
case "$CFG_DESC" in
  *' …') fail "truncation trims the trailing space" ;;
  *)     pass "truncation trims the trailing space" ;;
esac

# ---- ui helpers ----
. "$HERE/../lib/ui.sh"
assert_eq "" "$(keel_banner 0.0.0 abc123)" "banner prints nothing when stdout is captured"
( LC_ALL=C LC_CTYPE=C LANG=C; keel_is_utf8 ) && fail "utf8 detection is false under LANG=C" || pass "utf8 detection is false under LANG=C"
# stderr is silenced because the assignment makes bash attempt setlocale, which warns
# on machines where that locale is not generated — irrelevant to the string match here.
( LC_ALL=en_US.UTF-8; keel_is_utf8 ) 2>/dev/null && pass "utf8 detection is true under a UTF-8 locale" || fail "utf8 detection is true under a UTF-8 locale"
( NO_COLOR=1; keel_use_color ) && fail "NO_COLOR disables color" || pass "NO_COLOR disables color"

# ---- install path stays non-interactive ----
CFG_S="$(new_sandbox)"
CFG_OUT="$(bash "$HERE/../bootstrap.sh" --dir "$CFG_S")"
case "$CFG_OUT" in
  *█*) fail "captured install output carries no banner" ;;
  *)   pass "captured install output carries no banner" ;;
esac

# ---- discovery print ----
echo "$CFG_OUT" | grep -qF "optional packs not installed:" \
  && pass "install names the packs it did not install" || fail "install names the packs it did not install"
echo "$CFG_OUT" | grep -F "optional packs not installed:" | grep -qF "ship" \
  && pass "discovery lists the opt-in ship pack" || fail "discovery lists the opt-in ship pack"
echo "$CFG_OUT" | grep -qF -- "--configure" \
  && pass "discovery points at --configure" || fail "discovery points at --configure"

# An installed pack must drop off the "not installed" list.
CFG_S2="$(new_sandbox)"
CFG_OUT2="$(bash "$HERE/../bootstrap.sh" --dir "$CFG_S2" --pack=ship)"
echo "$CFG_OUT2" | grep -F "optional packs not installed:" | grep -qF "ship" \
  && fail "an installed pack is not offered again" || pass "an installed pack is not offered again"

# ---- guards ----
# Wrong directory beats no-TTY: the more specific error wins even from a pipe.
CFG_EMPTY="$(new_sandbox)"
CFG_G1="$(bash "$HERE/../bootstrap.sh" --dir "$CFG_EMPTY" --configure 2>&1 </dev/null || true)"
case "$CFG_G1" in
  *"no keel install at"*) pass "--configure refuses a directory keel does not own" ;;
  *) fail "--configure refuses a directory keel does not own (got: $CFG_G1)" ;;
esac
if bash "$HERE/../bootstrap.sh" --dir "$CFG_EMPTY" --configure >/dev/null 2>&1 </dev/null; then
  fail "--configure exits nonzero on a non-keel directory"
else
  pass "--configure exits nonzero on a non-keel directory"
fi

# No TTY: refuse and name the non-interactive equivalent, rather than hang on read.
CFG_G2="$(bash "$HERE/../bootstrap.sh" --dir "$CFG_S" --configure 2>&1 </dev/null || true)"
case "$CFG_G2" in
  *"needs an interactive terminal"*) pass "--configure refuses without a TTY" ;;
  *) fail "--configure refuses without a TTY (got: $CFG_G2)" ;;
esac
case "$CFG_G2" in
  *"--pack="*) pass "the TTY refusal names the non-interactive flags" ;;
  *) fail "the TTY refusal names the non-interactive flags" ;;
esac

# ---- end-to-end through a pty (skipped where util-linux `script` is absent) ----
if command -v script >/dev/null 2>&1; then
  # Resolve ship's menu index from the same glob the menu uses, so adding a pack to
  # the repo does not silently retarget this test at a different row.
  CFG_IDX=0; CFG_I=0
  for d in "$HERE"/../packs/*/; do
    [ -f "${d}install.sh" ] || continue
    CFG_I=$((CFG_I + 1))
    [ "$(basename "$d")" = "ship" ] && CFG_IDX=$CFG_I
  done
  CFG_S3="$(new_sandbox)"
  bash "$HERE/../bootstrap.sh" --dir "$CFG_S3" >/dev/null 2>&1
  printf '%s\n\n' "$CFG_IDX" | script -q -e -c "bash '$HERE/../bootstrap.sh' --dir '$CFG_S3' --configure" /dev/null >/dev/null 2>&1 || true
  assert_contains "$CFG_S3/.specify/keel.json" '"ship"' "pty: toggling a row installs the pack and records it"
  assert_file "$CFG_S3/.claude/skills/observability-and-instrumentation/SKILL.md" "pty: the selected pack's files land in the target"

  # Confirming without toggling anything must be a no-op, not a silent uninstall.
  printf '\n' | script -q -e -c "bash '$HERE/../bootstrap.sh' --dir '$CFG_S3' --configure" /dev/null >/dev/null 2>&1 || true
  assert_contains "$CFG_S3/.specify/keel.json" '"ship"' "pty: confirming unchanged keeps the recorded packs"

  # Aborting must not write, even after toggles.
  CFG_S4="$(new_sandbox)"
  bash "$HERE/../bootstrap.sh" --dir "$CFG_S4" >/dev/null 2>&1
  printf '%s\nq\n' "$CFG_IDX" | script -q -e -c "bash '$HERE/../bootstrap.sh' --dir '$CFG_S4' --configure" /dev/null >/dev/null 2>&1 || true
  assert_eq "" "$(node -pe "require('$CFG_S4/.specify/keel.json').packs.join(',')")" "pty: q aborts without applying toggles"
  rm -rf "$CFG_S3" "$CFG_S4"
else
  pass "pty end-to-end skipped (no util-linux script)"
fi

rm -rf "$CFG_S" "$CFG_S2" "$CFG_EMPTY"
