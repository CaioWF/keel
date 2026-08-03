#!/usr/bin/env bash
# keel terminal UI helpers — sourced by bootstrap.sh and lib/configure.sh.
#
# Everything decorative is gated on stdout being a TTY. That single guard does double
# duty: it makes the banner look right for a human, and it keeps the banner out of the
# test files (and any agent/CI run) that capture bootstrap output with `$(...)` or
# `>/dev/null`. Non-TTY callers see byte-identical output to before this file existed.

# keel_is_tty — stdout is an interactive terminal.
keel_is_tty() { [ -t 1 ]; }

# keel_use_color — TTY plus the usual opt-outs (NO_COLOR is the cross-tool convention).
keel_use_color() {
  keel_is_tty || return 1
  [ -z "${NO_COLOR:-}" ] || return 1
  [ "${TERM:-}" != "dumb" ] || return 1
  return 0
}

# keel_is_utf8 — the block-drawing banner needs a UTF-8 locale; otherwise fall back
# to plain ASCII rather than printing mojibake.
keel_is_utf8() {
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8*|*utf-8*|*UTF8*|*utf8*) return 0 ;;
    *) return 1 ;;
  esac
}

# keel_banner <version> <commit> — the wordmark. No-op unless stdout is a TTY.
keel_banner() {
  local version="${1:-unknown}" commit="${2:-unknown}" c="" d="" r=""
  keel_is_tty || return 0
  if keel_use_color; then c=$'\033[36m'; d=$'\033[2m'; r=$'\033[0m'; fi

  printf '\n%s' "$c"
  if keel_is_utf8; then
    printf '%s\n' \
      '  ██╗  ██╗███████╗███████╗██╗     ' \
      '  ██║ ██╔╝██╔════╝██╔════╝██║     ' \
      '  █████╔╝ █████╗  █████╗  ██║     ' \
      '  ██╔═██╗ ██╔══╝  ██╔══╝  ██║     ' \
      '  ██║  ██╗███████╗███████╗███████╗' \
      '  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝'
  else
    printf '%s\n' \
      '   _  __ ___ ___ _    ' \
      '  | |/ /| __| __| |   ' \
      "  | ' < | _|| _|| |__ " \
      '  |_|\_\|___|___|____|'
  fi
  printf '%s%s  spec-driven development harness · v%s (%s)%s\n\n' "$r" "$d" "$version" "$commit" "$r"
}

# keel_dim <text> — secondary line, dimmed only when color is on.
keel_dim() {
  if keel_use_color; then printf '\033[2m%s\033[0m\n' "$1"; else printf '%s\n' "$1"; fi
}
