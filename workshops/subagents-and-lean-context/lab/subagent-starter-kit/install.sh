#!/usr/bin/env bash
# Install the kit's three read-only sample subagents for Claude Code and Cursor.
#
#   bash install.sh             preview, ask once, then install
#   bash install.sh --dry-run   preview only, change nothing
#   bash install.sh --check     read only: report drift and lint agent files
#
# Claude Code copies go to ~/.claude/agents/, Cursor copies to ~/.cursor/agents/.
# A same-name file that is yours is left alone unless you pass --force, and
# anything replaced is backed up under ~/.subagent-starter-kit/backups/ first.
# Works on the macOS system bash (3.2) and on bash 5.
set -eu

KIT="$(cd "$(dirname "$0")" && pwd)"
AGENT_NAMES="code-reader doc-reader context-checker"
STATE_DIR="$HOME/.subagent-starter-kit"
STATE="$STATE_DIR/installed.tsv"
TOOLS="claude,cursor"
DRY=0 YES=0 CHECK=0 FORCE=0

usage() {
  cat <<'USAGE'
Usage: bash install.sh [options]

Installs code-reader, doc-reader and context-checker for Claude Code
(~/.claude/agents/) and Cursor (~/.cursor/agents/).

  --dry-run          show what would change, change nothing
  --yes, -y          do not ask before installing
  --force            also replace same-name files that are yours (backed up first)
  --tools=LIST       claude, cursor or claude,cursor (default: both)
  --check            read only: report drift and lint every agent file
  -h, --help         show this help

Undo: bash ~/.subagent-starter-kit/uninstall.sh
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    --force) FORCE=1 ;;
    --check) CHECK=1 ;;
    --tools=*) TOOLS="${arg#--tools=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

for t in $(printf '%s' "$TOOLS" | tr ',' ' '); do
  case "$t" in
    claude|cursor) ;;
    *) echo "Unknown tool in --tools: $t (use claude, cursor or claude,cursor)" >&2; exit 2 ;;
  esac
done
[ -n "$(printf '%s' "$TOOLS" | tr -d ', ')" ] || { echo "--tools is empty" >&2; exit 2; }

want() { case ",$TOOLS," in *",$1,"*) return 0 ;; esac; return 1; }
# Show paths as ~/... in messages (the tilde is meant literally here).
# shellcheck disable=SC2088
tilde() { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }
sum() { cksum < "$1" | awk '{ print $1 "-" $2 }'; }
# The checksum (field 2) or backup (field 3) last recorded for a destination.
recorded() {
  [ -f "$STATE" ] || return 0
  awk -F'\t' -v d="$1" -v f="$2" '$1 == d { s = $f } END { if (s != "") print s }' "$STATE"
}

# status SRC DEST prints one of: missing, current, older, yours
status() {
  if [ ! -e "$2" ] && [ ! -L "$2" ]; then echo missing
  elif [ -L "$2" ] || [ ! -f "$2" ]; then echo yours
  elif cmp -s "$1" "$2"; then echo current
  elif [ "$(recorded "$2" 2)" = "$(sum "$2")" ]; then echo older
  else echo yours
  fi
}

# lint FILE TOOL prints one problem per line, nothing when the file is fine.
# A simple line check, not a full YAML parser.
lint() {
  if [ -L "$1" ] && [ ! -e "$1" ]; then echo "broken link"; return; fi
  awk -v tool="$2" -v q="'" '
    NR == 1 {
      if ($0 != "---") { nofm = 1; exit }
      infm = 1; next
    }
    infm && $0 == "---" { closed = 1; exit }
    infm {
      if ($0 ~ /^\t/) { print "line " NR ": starts with a tab; YAML needs spaces"; next }
      if ($0 ~ /^[ ]/ || $0 ~ /^[ \t]*$/ || $0 ~ /^#/) next
      if ($0 !~ /^[A-Za-z_][A-Za-z0-9_-]*:([ ]|$)/) { print "line " NR ": not a key: value line"; next }
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:[ ]*/, "", val); sub(/[ ]+$/, "", val)
      if (val !~ ("^[\"" q "|>]") && val ~ /: /) print "line " NR ": the " key " value has \": \" in it; wrap the value in quotes"
      if (key == "name") { hasname = 1; name = val; gsub("^[\"" q "]|[\"" q "]$", "", name) }
      if (key == "description") hasdesc = 1
    }
    END {
      if (nofm) {
        if (tool == "claude") print "line 1 is not ---, so Claude Code treats the file as documentation"
        else print "no frontmatter, so Cursor has no description to route on"
        exit
      }
      if (!closed) { print "the frontmatter never closes (no second ---)"; exit }
      if (tool == "claude") {
        if (!hasname) print "no name, so Claude Code treats the file as documentation"
        else if (name ~ /^-/ || name ~ /:/ || length(name) > 256) print "name " name " starts with -, has a colon or is over 256 characters, so Claude Code skips it"
        if (hasname && !hasdesc) print "a name but no description, so Claude Code skips it"
      } else if (!hasdesc) print "no description, so Cursor has nothing to route on"
      if (hasname && name !~ /^[a-z0-9-]+$/) print "name " name " should be lowercase letters, digits and hyphens"
    }' "$1"
}

if [ "$CHECK" = 1 ]; then
  drift=0 problems=0
  echo "Sample subagents:"
  for t in claude cursor; do
    want "$t" || continue
    for a in $AGENT_NAMES; do
      src="$KIT/agents/$t/$a.md" dest="$HOME/.$t/agents/$a.md"
      case "$(status "$src" "$dest")" in
        current) echo "  ok      $(tilde "$dest")" ;;
        missing) echo "  DRIFT   $(tilde "$dest"): missing (run install.sh)"; drift=1 ;;
        older)   echo "  DRIFT   $(tilde "$dest"): the kit's older copy (run install.sh)"; drift=1 ;;
        yours)   echo "  yours   $(tilde "$dest"): changed by you or not the kit's; left alone" ;;
      esac
    done
  done
  echo "Frontmatter of every agent file:"
  for t in claude cursor; do
    want "$t" || continue
    dir="$HOME/.$t/agents"
    [ -d "$dir" ] || { echo "  (no $(tilde "$dir")/ yet)"; continue; }
    found=0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      found=1
      out="$(lint "$f" "$t")"
      if [ -n "$out" ]; then
        problems=1
        printf '%s\n' "$out" | while IFS= read -r line; do echo "  LINT    $(tilde "$f"): $line"; done
      fi
    done <<LIST
$(find "$dir" \( -type f -o -type l \) -name '*.md' | LC_ALL=C sort)
LIST
    [ "$found" = 1 ] || echo "  (no agent files in $(tilde "$dir")/)"
  done
  [ "$problems" = 1 ] || echo "  no problems found"
  if want claude; then
    echo "For a full YAML parse in Claude Code v2.1.233 or later: claude plugin validate ~/.claude/agents"
  fi
  if [ "$drift" = 1 ] || [ "$problems" = 1 ]; then
    [ "$drift" = 0 ] || echo "Drift found. Fix: bash $(tilde "$KIT")/install.sh"
    [ "$problems" = 0 ] || echo "Lint problems found. Fix the lines above; a skipped file looks like an agent that never fires."
    exit 1
  fi
  echo "No drift. No lint problems."
  exit 0
fi

# Build the plan: one line per change, as "action tool name".
PLAN="" changes=0 new_claude_dir=0
[ -d "$HOME/.claude/agents" ] || new_claude_dir=1
echo "Subagent starter kit: install plan"
for t in claude cursor; do
  want "$t" || continue
  for a in $AGENT_NAMES; do
    src="$KIT/agents/$t/$a.md" dest="$HOME/.$t/agents/$a.md"
    st="$(status "$src" "$dest")"
    case "$st" in
      missing) echo "  add      $(tilde "$dest")"; act=add ;;
      current) echo "  ok       $(tilde "$dest") (already current)"; act="" ;;
      older)   echo "  update   $(tilde "$dest") (the kit's older copy; backed up first)"; act=update ;;
      yours)
        if [ "$FORCE" = 1 ]; then echo "  replace  $(tilde "$dest") (yours; backed up first)"; act=replace
        else echo "  skip     $(tilde "$dest") (yours; left alone, --force replaces it)"; act=""; fi ;;
    esac
    if [ -n "$act" ]; then PLAN="$PLAN$act $t $a
"; changes=$((changes + 1)); fi
  done
done
if ! cmp -s "$KIT/uninstall.sh" "$STATE_DIR/uninstall.sh" 2>/dev/null; then
  echo "  add      $(tilde "$STATE_DIR")/uninstall.sh (the undo script)"
  changes=$((changes + 1))
fi

if [ "$changes" = 0 ]; then echo "Nothing to change."; exit 0; fi
if [ "$DRY" = 1 ]; then echo "Dry run: nothing changed."; exit 0; fi
if [ "$YES" = 0 ]; then
  if [ ! -t 0 ]; then echo "No terminal to ask. Re-run with --yes to install." >&2; exit 1; fi
  printf 'Install? [y/N] '
  read -r answer || answer=""
  case "$answer" in y|Y|yes|YES) ;; *) echo "Nothing changed."; exit 1 ;; esac
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$STATE_DIR"
touch "$STATE"
while read -r act t a; do
  [ -n "$act" ] || continue
  src="$KIT/agents/$t/$a.md" dest="$HOME/.$t/agents/$a.md"
  backup="$(recorded "$dest" 3)"
  if [ "$act" = update ] || [ "$act" = replace ]; then
    b="$STATE_DIR/backups/$STAMP/$t/$a.md"
    mkdir -p "$(dirname "$b")"
    cp -P "$dest" "$b"
    # Only a file that was yours is restored on uninstall.
    [ "$act" = replace ] && backup="$b"
    rm -f "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  awk -F'\t' -v d="$dest" '$1 != d' "$STATE" > "$STATE.tmp"
  printf '%s\t%s\t%s\n' "$dest" "$(sum "$dest")" "${backup:--}" >> "$STATE.tmp"
  mv "$STATE.tmp" "$STATE"
  echo "  done     $(tilde "$dest")"
done <<PLANLIST
$PLAN
PLANLIST
cp "$KIT/uninstall.sh" "$STATE_DIR/uninstall.sh"
chmod 755 "$STATE_DIR/uninstall.sh"

echo
echo "Installed. Try it:"
want cursor && echo "  Cursor:      /code-reader explain src/main.ts"
want claude && echo "  Claude Code: @agent-code-reader explain src/main.ts   (or type @ and pick it)"
if want claude && [ "$new_claude_dir" = 1 ]; then
  echo "$(tilde "$HOME/.claude/agents")/ is new, so restart any open Claude Code session once to load it."
fi
echo "Check later: bash $(tilde "$KIT")/install.sh --check"
echo "Undo:        bash ~/.subagent-starter-kit/uninstall.sh"
