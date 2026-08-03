#!/usr/bin/env bash
# keel --configure — interactive selection of optional packs and agent views.
#
# Deliberately OUT of the install/update path. `bootstrap.sh` stays non-interactive
# because the test suite, CI, and the agent itself run it with stdin/stdout captured;
# a stdin read there would hang them. Configuration is therefore its own explicit
# command: whoever types `--configure` knows it is going to ask.
#
# It also does not decide architecture STYLE (clean/hexagonal/onion/layered). That is
# one mutually exclusive, hard-to-reverse choice that wants a rationale, and install is
# the moment of least information (often an empty project). It belongs to the
# constitution plus an ADR, written in-session where the agent can read the repo and
# explain the trade-off. See docs/design-notes/install-configuration.md.
#
# Sourceable: defining the helpers has no side effects, so tests exercise the set
# arithmetic without a pty. Only direct execution runs the menu.

# keel_cfg_in_set <item> <space-separated set>
keel_cfg_in_set() {
  case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# keel_cfg_toggle <item> <set> — prints the set with <item> added or removed.
keel_cfg_toggle() {
  local item="$1" set="$2" out="" x
  if keel_cfg_in_set "$item" "$set"; then
    for x in $set; do [ "$x" = "$item" ] || out="${out:+$out }$x"; done
  else
    out="${set:+$set }$item"
  fi
  printf '%s' "$out"
}

# keel_cfg_filter <kind> <set> — prints the bare names of "<kind>:<name>" entries.
keel_cfg_filter() {
  local kind="$1" set="$2" out="" x
  for x in $set; do
    case "$x" in "$kind":*) out="${out:+$out }${x#*:}" ;; esac
  done
  printf '%s' "$out"
}

# keel_cfg_join <space-separated> — prints the same list comma-separated.
keel_cfg_join() {
  local out="" x
  for x in $1; do out="${out:+$out,}$x"; done
  printf '%s' "$out"
}

# keel_cfg_pack_desc <path/to/install.sh> — the one-line summary every pack carries on
# line 2 as `# <name> pack — <text>`. The sentence usually wraps onto line 3, so cut on
# a word boundary and mark the elision; a mid-word chop reads like a bug.
keel_cfg_pack_desc() {
  local line max=58
  line="$(sed -n '2p' "$1" 2>/dev/null || true)"
  line="${line#\#}"; line="${line# }"
  case "$line" in *' pack — '*) line="${line#* pack — }" ;; esac
  if [ "${#line}" -gt "$max" ]; then
    line="${line:0:$max}"
    line="${line% *}…"
  fi
  printf '%s' "$line"
}

keel_cfg_usage() {
  cat >&2 <<'EOF'
[keel] --configure needs an interactive terminal.
       Non-interactive callers select directly:
         bootstrap.sh --dir <target> --pack=a,b --agent=x,y
EOF
}

keel_cfg_main() {
  local TARGET="$PWD" SELF="" AVAIL_AGENTS="" FORCE=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) TARGET="$2"; shift 2 ;;
      --self) SELF="$2"; shift 2 ;;
      --agents-available) AVAIL_AGENTS="$2"; shift 2 ;;
      --force) FORCE=1; shift ;;
      *) echo "[keel] configure: unknown arg: $1" >&2; return 2 ;;
    esac
  done
  [ -n "$SELF" ] || { echo "[keel] configure: --self is required" >&2; return 2; }

  # Guard 1: refuse a directory keel does not own, rather than render an empty screen
  # and then stamp a manifest onto a project that never asked for one. Checked before
  # the TTY guard so the more specific error wins — pointing --configure at the wrong
  # directory is worth saying out loud even from a pipe.
  local MF="$TARGET/.specify/keel.json"
  if [ ! -f "$MF" ]; then
    echo "[keel] no keel install at $TARGET (missing .specify/keel.json)." >&2
    echo "       Run: bootstrap.sh --dir $TARGET" >&2
    return 1
  fi

  # Guard 2: a menu with nothing to read from is a hang, not a feature.
  if [ ! -t 0 ] || [ ! -t 1 ]; then keel_cfg_usage; return 2; fi

  # shellcheck source=lib/ui.sh
  . "$SELF/lib/ui.sh"

  local cur_packs cur_agents
  cur_packs="$(KEEL_MF="$MF" node -pe 'try{(JSON.parse(require("fs").readFileSync(process.env.KEEL_MF,"utf8")).packs||[]).join(" ")}catch(e){""}')"
  cur_agents="$(KEEL_MF="$MF" node -pe 'try{(JSON.parse(require("fs").readFileSync(process.env.KEEL_MF,"utf8")).agents||[]).filter(a=>a!=="claude").join(" ")}catch(e){""}')"

  # Enumerate packs from disk, so a pack added to the repo shows up here with no edit.
  local CFG_KEYS=() CFG_LABELS=() CFG_DESCS=() CFG_KINDS=()
  local d name sh a
  for d in "$SELF"/packs/*/; do
    [ -d "$d" ] || continue
    sh="${d}install.sh"; [ -f "$sh" ] || continue
    name="$(basename "$d")"
    CFG_KEYS+=("pack:$name"); CFG_LABELS+=("$name"); CFG_KINDS+=("pack")
    CFG_DESCS+=("$(keel_cfg_pack_desc "$sh")")
  done
  for a in ${AVAIL_AGENTS//,/ }; do
    CFG_KEYS+=("agent:$a"); CFG_LABELS+=("$a"); CFG_KINDS+=("agent")
    CFG_DESCS+=("advisory view emitted from the Claude source")
  done

  if [ ${#CFG_KEYS[@]} -eq 0 ]; then
    echo "[keel] nothing to configure (no packs found under $SELF/packs)." >&2
    return 1
  fi

  # Seed the selection from what is already recorded, so confirming without touching
  # anything is a no-op rather than a silent uninstall.
  local SEL="" p
  for p in $cur_packs;  do SEL="${SEL:+$SEL }pack:$p";  done
  for p in $cur_agents; do SEL="${SEL:+$SEL }agent:$p"; done
  local SEL0="$SEL"

  local KEEL_VERSION KEEL_COMMIT
  KEEL_VERSION="$( [ -f "$SELF/VERSION" ] && head -n1 "$SELF/VERSION" | tr -d '[:space:]' || echo "unknown" )"
  KEEL_COMMIT="$(git -C "$SELF" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

  local i n tok reply mark last_kind
  n=${#CFG_KEYS[@]}
  while :; do
    keel_banner "$KEEL_VERSION" "$KEEL_COMMIT"
    printf '  configure  %s\n\n' "$TARGET"
    last_kind=""
    i=0
    while [ "$i" -lt "$n" ]; do
      if [ "${CFG_KINDS[$i]}" != "$last_kind" ]; then
        last_kind="${CFG_KINDS[$i]}"
        case "$last_kind" in
          pack)  printf '  Packs\n' ;;
          agent) printf '\n  Agent views\n' ;;
        esac
      fi
      mark=" "
      keel_cfg_in_set "${CFG_KEYS[$i]}" "$SEL" && mark="x"
      printf '   %2d) [%s] %-18s %s\n' "$((i + 1))" "$mark" "${CFG_LABELS[$i]}" "${CFG_DESCS[$i]}"
      i=$((i + 1))
    done
    printf '\n'
    keel_dim "  numbers toggle (e.g. 1 3) · Enter applies · q aborts"
    printf '  > '
    read -r reply || reply="q"
    case "$reply" in
      q|Q) printf '\n[keel] configure aborted — nothing changed.\n'; return 0 ;;
      "") break ;;
      *)
        for tok in $reply; do
          case "$tok" in
            ''|*[!0-9]*) printf '\n[keel] not a number: %s\n' "$tok"; sleep 1; continue ;;
          esac
          if [ "$tok" -ge 1 ] && [ "$tok" -le "$n" ]; then
            SEL="$(keel_cfg_toggle "${CFG_KEYS[$((tok - 1))]}" "$SEL")"
          else
            printf '\n[keel] out of range: %s\n' "$tok"; sleep 1
          fi
        done
        ;;
    esac
  done

  if [ "$SEL" = "$SEL0" ]; then
    printf '\n[keel] no change.\n'; return 0
  fi

  local new_packs new_agents
  new_packs="$(keel_cfg_filter pack "$SEL")"
  new_agents="$(keel_cfg_filter agent "$SEL")"

  # keel has no uninstall (a deliberate design decision, see the manifest note in #8).
  # Say so plainly instead of letting an unchecked box imply files were removed.
  local dropped="" x
  for x in $cur_packs; do keel_cfg_in_set "$x" "$new_packs" || dropped="${dropped:+$dropped }$x"; done
  if [ -n "$dropped" ]; then
    printf '\n[keel] deselected: %s\n' "$dropped"
    printf '       keel has no uninstall — those files stay; only the manifest record is dropped.\n'
    printf '       Auto-detected packs (stack-conventions on a TS project) return on the next bootstrap.\n'
  fi

  printf '\n'
  for x in $new_packs; do
    if keel_cfg_in_set "$x" "$cur_packs"; then
      echo "[keel] =pack $x (already installed)"
    else
      sh="$SELF/packs/$x/install.sh"
      if [ "$FORCE" -eq 1 ]; then bash "$sh" --dir "$TARGET" --force; else bash "$sh" --dir "$TARGET"; fi
    fi
  done

  if [ -n "$new_agents" ]; then
    node "$SELF/lib/emit-views.mjs" --dir "$TARGET" --agents "$(keel_cfg_join "$new_agents")"
  fi

  node "$SELF/lib/write-manifest.mjs" --dir "$TARGET" \
    --version "$KEEL_VERSION" --commit "$KEEL_COMMIT" \
    --agents "$(keel_cfg_join "$new_agents")" --packs "$(keel_cfg_join "$new_packs")"

  printf '[keel] configured %s\n' "$TARGET"
}

# Run the menu only when executed, not when sourced for testing.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
  keel_cfg_main "$@"
fi
