#!/usr/bin/env bash
set -euo pipefail
SELF="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; FORCE=0; AGENTS=""; PACKS=""; STATUS=0; CONFIGURE=0
ALL_EXTRA="codex,cursor,copilot,gemini,windsurf"
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --dir) TARGET="$2"; shift 2 ;;
    --all) AGENTS="$ALL_EXTRA"; shift ;;
    --agent=*) AGENTS="${1#--agent=}"; shift ;;
    --pack=*) PACKS="${1#--pack=}"; shift ;;
    --status) STATUS=1; shift ;;
    --configure) CONFIGURE=1; shift ;;
    *) echo "[keel] unknown arg: $1" >&2; exit 2 ;;
  esac
done

# shellcheck source=lib/ui.sh
. "$SELF/lib/ui.sh"

# keel source version (semver from VERSION file) + exact commit of this clone.
# VERSION is the in-repo source of truth; the sha pins what was actually installed.
# Both degrade to "unknown" gracefully (no file / SELF not a git repo).
KEEL_VERSION="$( [ -f "$SELF/VERSION" ] && head -n1 "$SELF/VERSION" | tr -d '[:space:]' || echo "unknown" )"
KEEL_COMMIT="$(git -C "$SELF" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

# Wordmark. No-op unless stdout is a TTY, so captured/CI/agent runs are byte-identical.
# Skipped under --configure, which redraws its own banner on every menu repaint.
[ "$CONFIGURE" -eq 1 ] || keel_banner "$KEEL_VERSION" "$KEEL_COMMIT"

# --status: read the target's manifest and report; do not install.
if [ "$STATUS" -eq 1 ]; then
  node "$SELF/lib/keel-status.mjs" --dir "$TARGET" --source-version "$KEEL_VERSION" --source-commit "$KEEL_COMMIT"
  exit $?
fi

# --configure: interactive pack/agent selection. Its own command on purpose — the
# install path must stay non-interactive for the test suite, CI and the agent, all of
# which run bootstrap with stdin/stdout captured.
if [ "$CONFIGURE" -eq 1 ]; then
  CFG_ARGS=(--dir "$TARGET" --self "$SELF" --agents-available "$ALL_EXTRA")
  [ "$FORCE" -eq 1 ] && CFG_ARGS+=(--force)
  bash "$SELF/lib/configure.sh" "${CFG_ARGS[@]}"
  exit $?
fi

mkdir -p "$TARGET"
INSTALLED_PACKS=""  # accumulates packs actually installed (explicit + detected), for the manifest
note_pack() { case ",$INSTALLED_PACKS," in *",$1,"*) : ;; *) INSTALLED_PACKS="${INSTALLED_PACKS:+$INSTALLED_PACKS,}$1" ;; esac; }

# copy_file <src> <dest>
copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "[keel] =$dest"; return 0
  fi
  cp "$src" "$dest"; echo "[keel] +$dest"
}
# copy_tree <srcdir> <destdir> [skip_rel...]
# skip_rel: relative path(s) to exclude (handled separately, e.g. living registries).
copy_tree() {
  local srcdir="$1" destdir="$2"; shift 2
  local skips=("$@")
  [ -d "$srcdir" ] || return 0
  find "$srcdir" -type f | while read -r f; do
    local rel="${f#"$srcdir"/}" s
    for s in "${skips[@]}"; do [ "$rel" = "$s" ] && continue 2; done
    copy_file "$f" "$destdir/$rel"
  done
}
# copy_file_once <src> <dest>: seed once, NEVER overwrite — even under --force.
# For living project artifacts (STATE.md, ADRs) that keel starts but the project
# then owns and edits; forcing them would clobber real work.
copy_file_once() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then echo "[keel] =$dest (seeded, kept)"; return 0; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"; echo "[keel] +$dest"
}
# copy_tree_once <srcdir> <destdir>: seed-once semantics for a whole tree.
copy_tree_once() {
  local srcdir="$1" destdir="$2"
  [ -d "$srcdir" ] || return 0
  find "$srcdir" -type f | while read -r f; do
    local rel="${f#"$srcdir"/}"
    copy_file_once "$f" "$destdir/$rel"
  done
}

# review-lenses.txt and impl-conventions.txt are LIVING registries — packs append to
# them, so seed each once and never force (forcing would wipe pack-registered entries
# on every update).
copy_tree "$SELF/core/specify"       "$TARGET/.specify"  review-lenses.txt impl-conventions.txt
copy_file_once "$SELF/core/specify/review-lenses.txt" "$TARGET/.specify/review-lenses.txt"
copy_file_once "$SELF/core/specify/impl-conventions.txt" "$TARGET/.specify/impl-conventions.txt"
copy_tree "$SELF/core/gates"         "$TARGET/.specify/gates"
copy_tree_once "$SELF/core/docs"     "$TARGET/docs"  # living artifacts — seed once, never force
copy_tree "$SELF/core/scripts"       "$TARGET/scripts"   # human-side tooling (keel-watch)
copy_tree "$SELF/core/claude/skills" "$TARGET/.claude/skills"
copy_tree "$SELF/core/claude/hooks"  "$TARGET/.claude/hooks"
mkdir -p "$TARGET/.claude/skills" "$TARGET/.claude/hooks"
chmod +x "$TARGET/.claude/hooks/"*.mjs 2>/dev/null || true
# Only the scripts keel ships — `scripts/` is the project's dir too, and marking a
# file executable is not ours to decide for anything we did not put there.
for f in "$SELF/core/scripts/"*; do
  [ -e "$f" ] && chmod +x "$TARGET/scripts/$(basename "$f")" 2>/dev/null || true
done
# CLAUDE.md is a LIVING doc: keel owns the body, but the `<!-- BEGIN:keel:<id> -->`
# blocks hold project-learned facts (environment, tests, conventions — written by the
# learn-session skill) and pack-contributed sections. A --force refresh rewrites the
# file from the template, so snapshot the blocks first and carry them back after.
# Packs run later and re-render their own, so a pack update still wins.
CLAUDE_PREV=""
if [ -f "$TARGET/CLAUDE.md" ] && [ "$FORCE" -eq 1 ]; then
  CLAUDE_PREV="$(mktemp)"; cp "$TARGET/CLAUDE.md" "$CLAUDE_PREV"
fi
copy_file "$SELF/core/claude/CLAUDE.md.tmpl" "$TARGET/CLAUDE.md"
if [ -n "$CLAUDE_PREV" ]; then
  node "$SELF/lib/inject-section.mjs" carry-over "$CLAUDE_PREV" "$TARGET/CLAUDE.md"
  rm -f "$CLAUDE_PREV"
fi

# The trivial-change marker is a LOCAL, short-lived door through the phase gate.
# A committed one would reopen it in every clone forever: checkout resets mtime,
# so the freshness window can never expire it. Ignore it rather than trusting that
# nobody runs `git add -A` while it exists.
if ! grep -qxF ".specify/trivial" "$TARGET/.gitignore" 2>/dev/null; then
  printf '\n# keel: local trivial-change marker (never commit — see .claude/hooks/phase-gate.mjs)\n.specify/trivial\n' >> "$TARGET/.gitignore"
  echo "[keel] +$TARGET/.gitignore (.specify/trivial)"
fi

# AGENTS.md -> CLAUDE.md (relative symlink), created only if absent or --force
if [ ! -e "$TARGET/AGENTS.md" ] || [ "$FORCE" -eq 1 ]; then
  ln -sf "CLAUDE.md" "$TARGET/AGENTS.md"; echo "[keel] +$TARGET/AGENTS.md"
else
  echo "[keel] =$TARGET/AGENTS.md"
fi

# Merge keel hook registrations into target settings.json (additive, dedup by command).
SETTINGS="$TARGET/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
node "$SELF/lib/merge-settings.mjs" "$SETTINGS" "$SELF/core/claude/settings.hooks.json"
echo "[keel] =merged hooks into $SETTINGS"

# Multi-client views: generate advisory views for selected extra clients from the
# canonical Claude source just installed. Default (no --agent/--all) = Claude-only.
# If codex is selected, emit-views replaces the AGENTS.md symlink with a real view.
if [ -n "$AGENTS" ]; then
  node "$SELF/lib/emit-views.mjs" --dir "$TARGET" --agents "$AGENTS"
fi

# Explicit pack dispatch (--pack=a,b). Runs after core install so packs layer
# on top of the seeded skills/registry. Each pack owns its own idempotent install.
if [ -n "$PACKS" ]; then
  IFS=',' read -ra PACK_LIST <<< "$PACKS"
  for p in "${PACK_LIST[@]}"; do
    PACK_SH="$SELF/packs/$p/install.sh"
    if [ -f "$PACK_SH" ]; then
      if [ "$FORCE" -eq 1 ]; then bash "$PACK_SH" --dir "$TARGET" --force; else bash "$PACK_SH" --dir "$TARGET"; fi
      note_pack "$p"
    else
      echo "[keel] unknown pack: $p (no $PACK_SH)" >&2; exit 2
    fi
  done
fi

# Stack detection -> optional pack dispatch (runs after core install). Only auto-runs
# packs the caller did not already request explicitly via --pack.
run_detected_pack() {
  local name="$1" sh="$SELF/packs/$1/install.sh"
  case ",$PACKS," in *",$name,"*) return 0 ;; esac  # already ran via --pack
  [ -f "$sh" ] || return 0
  if [ "$FORCE" -eq 1 ]; then bash "$sh" --dir "$TARGET" --force; else bash "$sh" --dir "$TARGET"; fi
  note_pack "$name"
}

# stack-conventions: implementation-time convention lenses. Auto-installed when a TS
# and/or Postgres/Prisma signal is present; the skills themselves are stack-scoped so
# an unrelated stack simply won't trigger the TS/PG lenses.
if [ -f "$TARGET/tsconfig.json" ] || grep -qi 'postgres\|prisma' "$TARGET/package.json" 2>/dev/null; then
  echo "[keel] stack signal (TS/Postgres) detected — stack-conventions pack"
  run_detected_pack stack-conventions
fi

if [ -f "$TARGET/package.json" ] && [ -f "$TARGET/tsconfig.json" ]; then
  echo "[keel] TS project detected — ts-clean-arch pack"
  # The TS pack ships in a later plan (Plan 2); absent in core, so this is a
  # no-op until then. Detection still prints so the seam is observable.
  PACK="$SELF/packs/ts-clean-arch/install.sh"
  if [ -f "$PACK" ]; then
    if [ "$FORCE" -eq 1 ]; then bash "$PACK" --dir "$TARGET" --force; else bash "$PACK" --dir "$TARGET"; fi
    note_pack "ts-clean-arch"
  fi
fi

# Install manifest: always stamp .specify/keel.json (version + commit + agents + packs +
# install/update timestamps). Unlike clients.json this is unconditional, so any project
# can answer "which keel is this?" and `bootstrap.sh --status` can report/flag staleness.
node "$SELF/lib/write-manifest.mjs" --dir "$TARGET" \
  --version "$KEEL_VERSION" --commit "$KEEL_COMMIT" \
  --agents "${AGENTS:-}" --packs "${INSTALLED_PACKS:-}"

echo "[keel] core installed at $TARGET"

# Discovery: opt-in packs are invisible by design (`ship` is "opt-in ONLY, never
# auto-detected"), and nobody reads --help. Naming what exists but is not installed is
# the cheapest fix that does not put a prompt in the install path.
AVAILABLE_PACKS=""
for d in "$SELF"/packs/*/; do
  [ -f "${d}install.sh" ] || continue
  p="$(basename "$d")"
  case ",$INSTALLED_PACKS," in *",$p,"*) continue ;; esac
  AVAILABLE_PACKS="${AVAILABLE_PACKS:+$AVAILABLE_PACKS, }$p"
done
if [ -n "$AVAILABLE_PACKS" ]; then
  keel_dim "[keel] optional packs not installed: $AVAILABLE_PACKS"
  keel_dim "[keel]   pick interactively: bootstrap.sh --dir $TARGET --configure"
fi
