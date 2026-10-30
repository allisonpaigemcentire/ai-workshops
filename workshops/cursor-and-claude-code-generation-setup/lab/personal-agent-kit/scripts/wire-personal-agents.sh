#!/usr/bin/env bash
# Point each product's home-directory wrapper at one personal file:
#   ~/.agents/instructions/shared.md
#
# Canonical:  ~/.agents/instructions/shared.md   (edit prefs here)
# Wrappers:
#   Claude     ~/.claude/CLAUDE.md               (@ import; live after body edits)
#   Cursor     ~/.cursor/rules/personal-instructions.mdc  (embed; re-run after edits)
#   Gemini     ~/.gemini/GEMINI.md               (embed; re-run after edits)
#
# Usage:
#   bash wire-personal-agents.sh
#   bash wire-personal-agents.sh --check
#   bash wire-personal-agents.sh --dry-run   # show what would change
#   bash wire-personal-agents.sh --adopt     # add a managed region to an
#                                            # existing CLAUDE.md / GEMINI.md
#   bash wire-personal-agents.sh --tools=claude,cursor,gemini
#   bash wire-personal-agents.sh --help
#
# Claude @-imports shared.md (live after body edits). Cursor and Gemini
# embed a copy so those products load the text even if they do not expand
# @-imports. Those two wrappers are stale until you re-run.

set -euo pipefail

SHARED="${AGENTS_SHARED:-$HOME/.agents/instructions/shared.md}"
CLAUDE_MD="${CLAUDE_MD:-$HOME/.claude/CLAUDE.md}"
CURSOR_MDC="${CURSOR_MDC:-$HOME/.cursor/rules/personal-instructions.mdc}"
GEMINI_MD="${GEMINI_MD:-$HOME/.gemini/GEMINI.md}"
IMPORT_LINE="@~/.agents/instructions/shared.md"
CANONICAL_MARK="<!-- canonical-shared.md -->"
BEGIN="<!-- managed-by: wire-personal-agents -->"
END="<!-- /managed-by: wire-personal-agents -->"
MDC_MARKER="managed-by: wire-personal-agents"

MODE="sync"
DRY=0
ADOPT=0
TOOLS="claude,cursor,gemini"
BACKUP_DIR="${KIT_BACKUP_DIR:-$HOME/.agent-kit-backups/$(date +%Y%m%d-%H%M%S)}"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    --dry-run) DRY=1 ;;
    --adopt) ADOPT=1 ;;
    --tools=*) TOOLS="${arg#--tools=}" ;;
    --tools)
      echo "Use --tools=claude,cursor,gemini" >&2
      exit 2
      ;;
    -h|--help)
      sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done

IFS=',' read -r -a _tools <<<"$TOOLS"
for t in "${_tools[@]}"; do
  case "$t" in
    claude|cursor|gemini) ;;
    *)
      echo "Unknown tool: $t (supported: claude,cursor,gemini)" >&2
      exit 2
      ;;
  esac
done

tool_wanted() {
  local name="$1"
  [[ ",$TOOLS," == *",$name,"* ]]
}

abs_path() {
  local path="$1"
  local dir base
  dir="$(cd "$(dirname "$path")" && pwd)"
  base="$(basename "$path")"
  printf '%s/%s\n' "$dir" "$base"
}

has_precedence() {
  grep -q "On conflict, follow the repo" "$SHARED" 2>/dev/null
}

shared_body() {
  cat "$SHARED"
}

claude_region() {
  cat <<EOF
$BEGIN
## Personal prefs (canonical)

Repo \`AGENTS.md\`, repo skills, repo hooks, and repo rules win. Edit
\`~/.agents/instructions/shared.md\`. Do not duplicate those lines here.

$IMPORT_LINE
$END
EOF
}

cursor_wrapper() {
  cat <<EOF
---
description: Personal prefs from ~/.agents/instructions/shared.md
alwaysApply: true
# $MDC_MARKER
---

Follow \`~/.agents/instructions/shared.md\`. On conflict with repo files,
follow the repo. Re-run \`wire-personal-agents.sh\` after you edit shared.md.

$CANONICAL_MARK

$(shared_body)
EOF
}

GEMINI_HEADER="# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict."

gemini_region() {
  cat <<EOF
$BEGIN

Follow \`~/.agents/instructions/shared.md\`. Re-run \`wire-personal-agents.sh\`
after you edit that file so this copy stays current.

$CANONICAL_MARK

$(shared_body)
$END
EOF
}


file_has_begin() {
  grep -qxF "$BEGIN" "$1" 2>/dev/null && grep -qxF "$END" "$1" 2>/dev/null
}

file_has_mdc_marker() {
  grep -qF "$MDC_MARKER" "$1" 2>/dev/null
}

# Copy a file into the backup folder before changing it. Backups live outside
# ~/.agents so they never end up in a git repo you make there.
backup_file() {
  local f="$1" rel
  [[ -f "$f" ]] || return 0
  rel="${f#"$HOME"/}"
  rel="${rel#/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  chmod 700 "$BACKUP_DIR"
  cp -p "$f" "$BACKUP_DIR/$rel"
  echo "  backed up $f -> $BACKUP_DIR/$rel"
}

# install_content <dest> <new-content-file> <label>
# Writes only when the content changes; backs up first; honors --dry-run.
install_content() {
  local dest="$1" src="$2" label="$3" verb
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    ok_msgs+=("$label unchanged: $dest")
    return 0
  fi
  if [[ -f "$dest" ]]; then verb="update"; else verb="create"; fi
  if (( DRY )); then
    ok_msgs+=("$label would $verb: $dest")
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  backup_file "$dest"
  cat "$src" >"$dest"
  ok_msgs+=("$label ${verb}d: $dest")
}

# render_region <dest> <region-text> <out-file>
# Replaces the managed region in place and keeps every other line as is.
# With --adopt, an unmanaged file gets the region appended instead.
render_region() {
  local dest="$1" region="$2" out="$3" rfile
  rfile="$(mktemp)"
  printf '%s\n' "$region" >"$rfile"
  if file_has_begin "$dest"; then
    awk -v begin="$BEGIN" -v end="$END" -v rf="$rfile" '
      $0 == begin && !done { while ((getline l < rf) > 0) print l; skip=1; done=1; next }
      skip && $0 == end { skip=0; next }
      skip { next }
      { print }
    ' "$dest" >"$out"
  else
    { cat "$dest"; printf '\n'; cat "$rfile"; } >"$out"
  fi
  rm -f "$rfile"
}

# upsert_wrapper <dest> <region-text> <new-file-text> <label>
upsert_wrapper() {
  local dest="$1" region="$2" fresh="$3" label="$4" tmp
  tmp="$(mktemp)"
  if [[ ! -f "$dest" ]]; then
    printf '%s\n' "$fresh" >"$tmp"
  elif file_has_begin "$dest" || (( ADOPT )); then
    if ! file_has_begin "$dest"; then
      if (( DRY )); then echo "$label would add a managed region to your existing $dest (your lines are kept)"
      else echo "$label: adding a managed region to your existing $dest (your lines are kept)"; fi
    fi
    render_region "$dest" "$region" "$tmp"
  else
    rm -f "$tmp"
    return 1
  fi
  install_content "$dest" "$tmp" "$label"
  rm -f "$tmp"
}

errors=0
ok_msgs=()

require_shared() {
  if [[ ! -f "$SHARED" ]]; then
    echo "Missing canonical file: $SHARED" >&2
    echo "Copy instructions/shared.template.md from the kit there, keep the Precedence block, then re-run." >&2
    exit 1
  fi
  if ! has_precedence; then
    echo "Canonical file must include the Precedence block (On conflict, follow the repo): $SHARED" >&2
    exit 1
  fi
}

check_contains() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if [[ ! -f "$file" ]]; then
    echo "Missing wrapper: $file ($label)" >&2
    errors=$((errors + 1))
    return 1
  fi
  if ! grep -qF "$needle" "$file"; then
    echo "Wrapper missing expected text ($label): $file" >&2
    errors=$((errors + 1))
    return 1
  fi
  return 0
}

# Text after the canonical marker, optional stop at END, drop one leading blank.
extract_canonical() {
  local file="$1"
  local stop_at_end="$2"
  awk -v mark="$CANONICAL_MARK" -v end="$END" -v stop="$stop_at_end" '
    $0 == mark { grab=1; next }
    grab && stop == 1 && $0 == end { exit }
    grab { print }
  ' "$file" | awk 'NR == 1 && $0 == "" { next } { print }' | trim_trailing_blanks
}

# Final newline added, trailing blank lines dropped (what $(...) does to the
# embed). The old /^$/ form left two or more trailing blank lines in place.
trim_trailing_blanks() {
  awk '{ print }' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

# Cursor and Gemini store a copy of shared.md. --check must
# compare that copy to the canonical file, not only look for a pointer line.
check_embed() {
  local file="$1"
  local label="$2"
  local stop_at_end="$3"
  if ! check_contains "$file" "$CANONICAL_MARK" "$label"; then
    return
  fi
  if ! cmp -s <(trim_trailing_blanks <"$SHARED") <(extract_canonical "$file" "$stop_at_end"); then
    echo "Wrapper embed stale ($label): $file — re-run wire-personal-agents.sh after editing shared.md" >&2
    errors=$((errors + 1))
    return
  fi
  ok_msgs+=("$label ok — $file")
}

require_shared

if [[ "$MODE" == "check" ]]; then
  if tool_wanted claude; then
    if check_contains "$CLAUDE_MD" "$IMPORT_LINE" "Claude"; then
      ok_msgs+=("Claude ok — $CLAUDE_MD")
    fi
  fi
  tool_wanted cursor && check_embed "$CURSOR_MDC" "Cursor" 0
  tool_wanted gemini && check_embed "$GEMINI_MD" "Gemini" 1
  if [[ "$errors" -gt 0 ]]; then
    echo "Personal agents wire: drift ($errors problem(s))" >&2
    exit 1
  fi
  echo "Personal agents wire: ok (${#ok_msgs[@]} wrapper(s) → $SHARED)"
  exit 0
fi

if tool_wanted claude; then
  if ! upsert_wrapper "$CLAUDE_MD" "$(claude_region)" "$(claude_region)" "Claude wrapper"; then
    echo "Conflict: $CLAUDE_MD exists and is not managed. Re-run with --adopt to add the managed region (your lines are kept, a backup is made)." >&2
    errors=$((errors + 1))
  fi
fi

if tool_wanted cursor; then
  if [[ ! -f "$CURSOR_MDC" ]] || file_has_mdc_marker "$CURSOR_MDC"; then
    _tmp="$(mktemp)"
    printf '%s\n' "$(cursor_wrapper)" >"$_tmp"
    install_content "$CURSOR_MDC" "$_tmp" "Cursor wrapper"
    rm -f "$_tmp"
  else
    echo "Conflict: $CURSOR_MDC exists and is not a wire-personal-agents wrapper. Rename it, then re-run." >&2
    errors=$((errors + 1))
  fi
fi

if tool_wanted gemini; then
  # Gemini's save_memory tool also writes to ~/.gemini/GEMINI.md, so only the
  # managed region is ever replaced; everything outside it is kept.
  if ! upsert_wrapper "$GEMINI_MD" "$(gemini_region)" "$GEMINI_HEADER
$(gemini_region)" "Gemini wrapper"; then
    echo "Conflict: $GEMINI_MD exists and is not managed. Re-run with --adopt to add the managed region (your lines are kept, a backup is made)." >&2
    errors=$((errors + 1))
  fi
fi

# Empty array + set -u is unbound on bash 3.2 (macOS default).
if ((${#ok_msgs[@]})); then
  for m in "${ok_msgs[@]}"; do
    echo "$m"
  done
fi

if [[ "$errors" -gt 0 ]]; then
  echo "Personal agents wire: incomplete ($errors conflict(s))" >&2
  exit 1
fi

if (( DRY )); then
  echo "Personal agents wire: dry run, nothing written"
  exit 0
fi
echo "Personal agents wire: ok (${#ok_msgs[@]} wrapper(s) → $SHARED)"
echo "Edit $SHARED. Re-run this script after edits if you use Cursor or Gemini."
