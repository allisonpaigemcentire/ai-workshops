#!/usr/bin/env bash
# One-command install of the personal agent kit for Cursor, Claude Code and
# Gemini CLI.
#
#   bash scripts/install.sh             # preview, ask, then install
#   bash scripts/install.sh --dry-run   # preview only; changes nothing
#   bash scripts/install.sh --yes       # no prompt (for scripts)
#
# Options:
#   --tools=claude,cursor,gemini   only wire these tools (default: all three)
#   --no-mcp                       do not add MCP servers
#   -h, --help
#
# Optional team skills MCP server (added only when both are set, needs uv):
#   KIT_SKILLS_FROM='git+https://github.com/<org>/<repo>.git@main#subdirectory=<dir>'
#   KIT_SKILLS_ENTRY='<console-script-name>'
#
# What it does, in order:
#   1. Copies the kit into ~/.agents/ (your shared.md and rules are never
#      overwritten; kit scripts, hooks and status line are updated, old copy
#      backed up).
#   2. Links rules, hooks and the status line into ~/.cursor and ~/.claude.
#   3. Writes the personal-prefs wrappers: ~/.claude/CLAUDE.md,
#      ~/.cursor/rules/personal-instructions.mdc, ~/.gemini/GEMINI.md.
#      Existing CLAUDE.md / GEMINI.md keep their lines; the kit adds one
#      marked region.
#   4. Merges hooks, the status line and MCP servers into ~/.cursor/hooks.json,
#      ~/.cursor/mcp.json, ~/.claude/settings.json, ~/.gemini/settings.json,
#      and (if the claude CLI is installed) Claude Code's user MCP list.
#      Adds only what is missing; never replaces your values.
#
# Every file is backed up to ~/.agent-kit-backups/<time>/ before it changes.
# Re-running is safe: an unchanged setup produces no writes and no backups.
# Undo: bash ~/.agents/scripts/uninstall.sh
set -euo pipefail

KIT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS="${AGENTS_HOME:-$HOME/.agents}"
STATE="$AGENTS/.kit-installed"
STAMP="$(date +%Y%m%d-%H%M%S)"
export KIT_BACKUP_DIR="${KIT_BACKUP_DIR:-$HOME/.agent-kit-backups/$STAMP}"
export AGENTS_HOME="$AGENTS"
SKILLS_FROM="${KIT_SKILLS_FROM:-}"
SKILLS_ENTRY="${KIT_SKILLS_ENTRY:-}"
ATLASSIAN_URL="https://mcp.atlassian.com/v1/mcp"

PREVIEW_ONLY=0
YES=0
MCP=1
TOOLS="claude,cursor,gemini"
for arg in "$@"; do
  case "$arg" in
    --dry-run) PREVIEW_ONLY=1 ;;
    -y|--yes) YES=1 ;;
    --no-mcp) MCP=0 ;;
    --tools=*) TOOLS="${arg#--tools=}" ;;
    -h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done
case ",$TOOLS," in *,claude,*|*,cursor,*|*,gemini,*) ;; *) echo "--tools needs claude, cursor and/or gemini" >&2; exit 2 ;; esac
for t in ${TOOLS//,/ }; do
  case "$t" in claude|cursor|gemini) ;; *) echo "Unknown tool: $t (supported: claude,cursor,gemini)" >&2; exit 2 ;; esac
done
want() { [[ ",$TOOLS," == *",$1,"* ]]; }

# ---------- prerequisites ----------
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 8))' 2>/dev/null; then
  echo "python3 (3.8 or newer) is required. On macOS run: xcode-select --install" >&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || echo "note: jq not found; the Claude status line needs it (brew install jq)."

DRY=1
CONFLICTS=0
LINK_CHANGES=0
say()  { echo "  $*"; }
record() { (( DRY )) || printf '%s\n' "$(IFS=$'\t'; echo "$*")" >>"$STATE"; }

backup_file() {
  local f="$1" rel
  [[ -f "$f" ]] || return 0
  rel="${f#"$HOME"/}"; rel="${rel#/}"
  mkdir -p "$KIT_BACKUP_DIR/$(dirname "$rel")"
  chmod 700 "$KIT_BACKUP_DIR"
  cp -p "$f" "$KIT_BACKUP_DIR/$rel"
  say "backed up $f -> $KIT_BACKUP_DIR/$rel"
}

# link <target> <link-path>: create a symlink; never replace a real file or a
# link that points somewhere else.
link() {
  local target="$1" dest="$2" current
  if [[ -L "$dest" ]]; then
    current="$(readlink "$dest")"
    [[ "$current" == "$target" ]] && return 0
    say "conflict (link points elsewhere, left alone): $dest"
    CONFLICTS=$((CONFLICTS + 1))
  elif [[ -e "$dest" ]]; then
    say "conflict (real file, left alone): $dest"
    CONFLICTS=$((CONFLICTS + 1))
  else
    LINK_CHANGES=$((LINK_CHANGES + 1))
    if (( DRY )); then say "would link $dest -> $target"; return 0; fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$target" "$dest"
    say "linked $dest"
    record link "$dest" "$target"
  fi
}

# Names in a kit folder plus any you added in ~/.agents (e.g. your own rules).
# shellcheck disable=SC2086  # $2 is a list of globs on purpose
names_in() {  # names_in <subdir> <globs>
  local d p f pats
  read -r -a pats <<<"$2"
  for d in "$KIT/$1" "$AGENTS/$1"; do
    for p in "${pats[@]}"; do
      for f in "$d"/$p; do if [[ -f "$f" ]]; then basename "$f"; fi; done
    done
  done | sort -u
}

steps() {
  echo "1. Kit files -> $AGENTS"
  local rel dest n=0
  while IFS= read -r rel; do
    dest="$AGENTS/$rel"
    if [[ ! -e "$dest" ]]; then
      if (( DRY )); then say "would copy $rel"; else mkdir -p "$(dirname "$dest")"; cp -p "$KIT/$rel" "$dest"; fi
      n=$((n + 1))
    else
      case "$rel" in
        scripts/*|hooks/*|statusline/*)   # kit code: keep it current
          if ! cmp -s "$KIT/$rel" "$dest"; then
            if (( DRY )); then say "would: update $dest (old copy backed up)"; else backup_file "$dest"; cp -p "$KIT/$rel" "$dest"; fi
            n=$((n + 1))
          fi ;;
      esac   # instructions/ and rules/ are yours once copied: never overwritten
    fi
  done < <(cd "$KIT" && find instructions rules hooks scripts statusline -type f ! -name '.DS_Store' ! -name '*.pyc' 2>/dev/null | sort)
  if [[ ! -f "$AGENTS/instructions/shared.md" ]]; then
    if (( DRY )); then say "would create instructions/shared.md from the template"; else cp "$KIT/instructions/shared.template.md" "$AGENTS/instructions/shared.md"; say "created $AGENTS/instructions/shared.md (fill in the <placeholders>)"; fi
    n=$((n + 1))
  fi
  if (( n == 0 )); then say "ok (nothing to copy)"; elif (( ! DRY )); then say "copied or updated $n file(s)"; fi

  echo "2. Links"
  local f
  LINK_CHANGES=0
  if want cursor || want claude; then
    # Cursor rules folder doubles as the source of the Claude rules mirror.
    while IFS= read -r f; do
      case "$f" in *.template.mdc) continue ;; esac
      link "$AGENTS/rules/$f" "$HOME/.cursor/rules/$f"
    done < <(names_in rules '*.mdc .claude-exclude')
  fi
  if want cursor; then
    while IFS= read -r f; do link "$AGENTS/hooks/cursor/$f" "$HOME/.cursor/hooks/$f"; done < <(names_in hooks/cursor '*')
  fi
  if want claude; then
    while IFS= read -r f; do link "$AGENTS/hooks/claude/$f" "$HOME/.claude/hooks/$f"; done < <(names_in hooks/claude '*')
    while IFS= read -r f; do link "$AGENTS/statusline/$f" "$HOME/.claude/$f"; done < <(names_in statusline '*')
  fi
  if [[ -d "$AGENTS/skills" ]]; then
    for f in "$AGENTS"/skills/*/; do
      [[ -d "$f" ]] || continue
      want cursor && link "${f%/}" "$HOME/.cursor/skills/$(basename "$f")"
      want claude && link "${f%/}" "$HOME/.claude/skills/$(basename "$f")"
    done
  fi

  (( LINK_CHANGES + CONFLICTS )) || say "ok (all links in place)"

  echo "3. Personal-prefs wrappers"
  local wire="$KIT/scripts/wire-personal-agents.sh" shared="$AGENTS/instructions/shared.md"
  [[ -f "$shared" ]] || shared="$KIT/instructions/shared.template.md"   # preview on a fresh machine
  local wargs=(--adopt "--tools=$TOOLS")
  (( DRY )) && wargs+=(--dry-run)
  if ! AGENTS_SHARED="$shared" bash "$wire" "${wargs[@]}" 2>&1 | sed 's/^/  /'; then
    CONFLICTS=$((CONFLICTS + 1))
  fi
  if want claude; then
    if (( DRY )); then
      say "would: mirror ~/.cursor/rules/*.mdc into ~/.claude/rules/ as links (sync-personal-rules.sh)"
    else
      # Record the mirror links sync creates so uninstall.sh removes them too
      # (including links to your own ~/.cursor/rules/*.mdc). Links that were
      # already there before this run are not recorded and stay yours.
      local before l
      before="$(for l in "$HOME"/.claude/rules/*.md; do [[ -L "$l" ]] && printf '%s\n' "$l"; done; true)"
      bash "$KIT/scripts/sync-personal-rules.sh" 2>&1 | sed 's/^/  /' || CONFLICTS=$((CONFLICTS + 1))
      for l in "$HOME"/.claude/rules/*.md; do
        [[ -L "$l" ]] || continue
        printf '%s\n' "$before" | grep -Fxq -- "$l" && continue
        record link "$l" "$(readlink "$l")"
      done
    fi
  fi

  echo "4. Config merges"
  local kargs=(merge "--tools=$TOOLS")
  (( MCP )) || kargs+=(--no-mcp)
  (( DRY )) && kargs+=(--dry-run)
  python3 "$KIT/scripts/kit_config.py" "${kargs[@]}" || CONFLICTS=$((CONFLICTS + 1))
  if want claude && (( MCP )); then
    if command -v claude >/dev/null 2>&1; then
      claude_mcp atlassian --transport http atlassian "$ATLASSIAN_URL"
      if [[ -n "$SKILLS_FROM" && -n "$SKILLS_ENTRY" ]] && command -v uvx >/dev/null 2>&1; then
        claude_mcp team-skills team-skills -- uvx --from "$SKILLS_FROM" "$SKILLS_ENTRY"
      fi
    else
      say "note: claude CLI not on PATH; Claude Code MCP servers not added (re-run after installing Claude Code)."
    fi
  fi
}

# claude_mcp <name> <args for 'claude mcp add' after --scope user>
claude_mcp() {
  local name="$1"; shift
  # Read ~/.claude.json for the name only. ('claude mcp get' would start the
  # server, so it is not used.)
  if python3 - "$name" <<'PYEOF' 2>/dev/null
import json, os, sys
try:
    with open(os.path.expanduser("~/.claude.json"), encoding="utf-8") as fh:
        servers = json.load(fh).get("mcpServers") or {}
except (OSError, ValueError):
    servers = {}
sys.exit(0 if sys.argv[1] in servers else 1)
PYEOF
  then
    say "ok      Claude Code MCP '$name' (already set; kept yours)"
    return 0
  fi
  if (( DRY )); then
    say "would: claude mcp add --scope user $name"
  elif claude mcp add --scope user "$@" >/dev/null 2>&1; then
    say "added   Claude Code MCP '$name' (user scope)"
    record claude-mcp "$name"
  else
    say "could not add Claude Code MCP '$name'; add it by hand (see README)"
    CONFLICTS=$((CONFLICTS + 1))
  fi
}

echo "Personal agent kit -> $HOME (tools: $TOOLS)"
echo
echo "== Preview: nothing has changed yet =="
steps
if (( PREVIEW_ONLY )); then
  echo
  echo "Dry run only. Run without --dry-run to install."
  exit 0
fi

if (( ! YES )); then
  if [[ -t 0 ]]; then
    echo
    read -r -p "Apply these changes? [y/N] " reply
    case "$reply" in y|Y|yes|YES) ;; *) echo "Nothing changed."; exit 0 ;; esac
  else
    echo "No terminal to confirm on. Re-run with --yes to install." >&2
    exit 1
  fi
fi

echo
echo "== Installing (backups go to $KIT_BACKUP_DIR) =="
DRY=0
CONFLICTS=0
mkdir -p "$AGENTS"
steps

echo
if [[ -d "$KIT_BACKUP_DIR" ]]; then echo "Backups: $KIT_BACKUP_DIR"; else echo "No existing files were changed, so no backups were needed."; fi
if (( CONFLICTS )); then
  echo "Done, with $CONFLICTS item(s) left for you (see 'conflict', 'SKIPPED' or 'Conflict' above)."
else
  echo "Done."
fi
cat <<MSG

Next:
  1. Fill in the <placeholders> in $AGENTS/instructions/shared.md, then re-run
     this installer (or: bash $AGENTS/scripts/wire-personal-agents.sh).
  2. Start a new chat in Cursor, Claude Code and Gemini CLI.
  3. MCP: Atlassian signs in with OAuth on first use. Token servers: see
     mcp.example.json; secrets go in env vars or the Keychain, never in files.
Check for drift any time:  bash $AGENTS/scripts/wire-personal-agents.sh --check
Undo:                      bash $AGENTS/scripts/uninstall.sh
MSG
