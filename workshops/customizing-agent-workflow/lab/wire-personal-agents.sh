#!/usr/bin/env bash
# Point each product's home-directory wrapper at one personal file:
#   ~/.agents/instructions/shared.md
#
# Canonical:  ~/.agents/instructions/shared.md   (edit prefs here)
# Wrappers:
#   Claude     ~/.claude/CLAUDE.md               (@ import; live after body edits)
#   Cursor     ~/.cursor/rules/personal-instructions.mdc
#   Gemini     ~/.gemini/GEMINI.md               (pointer + embedded copy)
#   Firebender ~/.firebender/rules/personal-instructions.mdc
#
# Usage:
#   bash wire-personal-agents.sh
#   bash wire-personal-agents.sh --check
#   bash wire-personal-agents.sh --tools=claude,cursor,gemini,firebender
#   bash wire-personal-agents.sh --help
#
# Gemini and Firebender embed a copy of shared.md so those products load the
# text even if they do not expand @-imports. Re-run this script after you edit
# shared.md if you use those products. Claude and Cursor wrappers stay live.

set -euo pipefail

SHARED="${AGENTS_SHARED:-$HOME/.agents/instructions/shared.md}"
CLAUDE_MD="${CLAUDE_MD:-$HOME/.claude/CLAUDE.md}"
CURSOR_MDC="${CURSOR_MDC:-$HOME/.cursor/rules/personal-instructions.mdc}"
GEMINI_MD="${GEMINI_MD:-$HOME/.gemini/GEMINI.md}"
FIREBENDER_MDC="${FIREBENDER_MDC:-$HOME/.firebender/rules/personal-instructions.mdc}"
IMPORT_LINE="@~/.agents/instructions/shared.md"
BEGIN="<!-- managed-by: wire-personal-agents -->"
END="<!-- /managed-by: wire-personal-agents -->"
MDC_MARKER="managed-by: wire-personal-agents"

MODE="sync"
TOOLS="claude,cursor,gemini,firebender"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    --tools=*) TOOLS="${arg#--tools=}" ;;
    --tools)
      echo "Use --tools=claude,cursor,gemini,firebender" >&2
      exit 2
      ;;
    -h|--help)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (try --help)" >&2
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

Follow \`~/.agents/instructions/shared.md\` as the source of personal
preferences on this machine. On conflict with repo files, follow the repo.

$IMPORT_LINE
EOF
}

gemini_wrapper() {
  cat <<EOF
# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict.
$BEGIN

Follow \`~/.agents/instructions/shared.md\`. Re-run \`wire-personal-agents.sh\`
after you edit that file so this copy stays current.

$IMPORT_LINE

$(shared_body)
$END
EOF
}

firebender_wrapper() {
  cat <<EOF
---
description: Personal prefs from ~/.agents/instructions/shared.md
alwaysApply: true
# $MDC_MARKER
---

Follow \`~/.agents/instructions/shared.md\`. On conflict with repo files,
follow the repo. Re-run \`wire-personal-agents.sh\` after you edit shared.md.

$IMPORT_LINE

$(shared_body)
EOF
}

file_has_begin() {
  grep -qF "$BEGIN" "$1" 2>/dev/null
}

file_has_mdc_marker() {
  grep -qF "$MDC_MARKER" "$1" 2>/dev/null
}

upsert_region() {
  local dest="$1"
  local region="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    printf '%s\n' "$region" >"$dest"
    return 0
  fi
  if file_has_begin "$dest"; then
    local tmp
    tmp="$(mktemp)"
    awk -v begin="$BEGIN" -v end="$END" '
      $0 == begin { skip=1; next }
      $0 == end { skip=0; next }
      skip { next }
      { print }
    ' "$dest" >"$tmp"
    printf '\n%s\n' "$region" >>"$tmp"
    mv "$tmp" "$dest"
    return 0
  fi
  return 1
}

# Existing unmanaged files must conflict. Do not append into CLAUDE.md or
# other wrappers that the user already owns.
write_or_replace_marked() {
  local dest="$1"
  local content="$2"
  local kind="$3"
  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    printf '%s\n' "$content" >"$dest"
    return 0
  fi
  if [[ "$kind" == "region" ]] && file_has_begin "$dest"; then
    upsert_region "$dest" "$content"
    return 0
  fi
  if [[ "$kind" == "mdc" ]] && file_has_mdc_marker "$dest"; then
    printf '%s\n' "$content" >"$dest"
    return 0
  fi
  return 1
}

errors=0
ok_msgs=()
warn_msgs=()

require_shared() {
  if [[ ! -f "$SHARED" ]]; then
    echo "Missing canonical file: $SHARED" >&2
    echo "Copy lab/templates/shared.md there, keep the Precedence block, then re-run." >&2
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

# Text after the import line, optional stop at END, drop one leading blank line.
extract_after_import() {
  local file="$1"
  local stop_at_end="$2"
  awk -v imp="$IMPORT_LINE" -v end="$END" -v stop="$stop_at_end" '
    $0 == imp { grab=1; next }
    grab && stop == 1 && $0 == end { exit }
    grab { print }
  ' "$file" | awk 'NR == 1 && $0 == "" { next } { print }' | sed -e :a -e '/^$/{$d;N;ba' -e '}'
}

# Gemini and Firebender store a copy of shared.md. --check must compare that
# copy to the canonical file, not only look for the @ import line.
check_embed() {
  local file="$1"
  local label="$2"
  local stop_at_end="$3"
  if ! check_contains "$file" "$IMPORT_LINE" "$label"; then
    return
  fi
  if ! cmp -s "$SHARED" <(extract_after_import "$file" "$stop_at_end"); then
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
  if tool_wanted cursor; then
    if check_contains "$CURSOR_MDC" "$IMPORT_LINE" "Cursor"; then
      ok_msgs+=("Cursor ok — $CURSOR_MDC")
    fi
  fi
  tool_wanted gemini && check_embed "$GEMINI_MD" "Gemini" 1
  tool_wanted firebender && check_embed "$FIREBENDER_MDC" "Firebender" 0
  if [[ "$errors" -gt 0 ]]; then
    echo "Personal agents wire: drift ($errors problem(s))" >&2
    exit 1
  fi
  echo "Personal agents wire: ok (${#ok_msgs[@]} wrapper(s) → $SHARED)"
  exit 0
fi

if tool_wanted claude; then
  if write_or_replace_marked "$CLAUDE_MD" "$(claude_region)" "region"; then
    ok_msgs+=("Claude wrapper: $CLAUDE_MD")
  else
    echo "Conflict: $CLAUDE_MD exists and is not managed. Add the managed region by hand or back up the file." >&2
    errors=$((errors + 1))
  fi
fi

if tool_wanted cursor; then
  if write_or_replace_marked "$CURSOR_MDC" "$(cursor_wrapper)" "mdc"; then
    ok_msgs+=("Cursor wrapper: $CURSOR_MDC")
  else
    echo "Conflict: $CURSOR_MDC exists and is not a wire-personal-agents wrapper. Back it up or add the managed-by marker." >&2
    errors=$((errors + 1))
  fi
fi

if tool_wanted gemini; then
  if [[ -f "$GEMINI_MD" ]] && ! file_has_begin "$GEMINI_MD"; then
    echo "Conflict: $GEMINI_MD exists and is not managed. Back it up, or insert $BEGIN … $END and re-run." >&2
    errors=$((errors + 1))
  else
    mkdir -p "$(dirname "$GEMINI_MD")"
    if [[ ! -f "$GEMINI_MD" ]] || file_has_begin "$GEMINI_MD"; then
      printf '%s\n' "$(gemini_wrapper)" >"$GEMINI_MD"
      ok_msgs+=("Gemini wrapper: $GEMINI_MD")
    fi
  fi
fi

if tool_wanted firebender; then
  if write_or_replace_marked "$FIREBENDER_MDC" "$(firebender_wrapper)" "mdc"; then
    ok_msgs+=("Firebender wrapper: $FIREBENDER_MDC")
  else
    echo "Conflict: $FIREBENDER_MDC exists and is not a wire-personal-agents wrapper. Back it up or add the managed-by marker." >&2
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

echo "Personal agents wire: ok (${#ok_msgs[@]} wrapper(s) → $SHARED)"
echo "Edit $SHARED. Re-run this script after edits if you use Gemini or Firebender."
