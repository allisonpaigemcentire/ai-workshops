#!/usr/bin/env bash
# Undo the personal agent kit install.
#
#   bash ~/.agents/scripts/uninstall.sh             # preview, ask, then undo
#   bash ~/.agents/scripts/uninstall.sh --dry-run   # preview only
#   bash ~/.agents/scripts/uninstall.sh --yes       # no prompt
#
# Removes only what the installer recorded in ~/.agents/.kit-installed:
#   - the links it made (only if they still point where it pointed them)
#   - the optional helpers (--with-helpers, or agents/install-sample-agents.sh:
#     code-reader, doc-reader and context-checker): the links in
#     ~/.claude/agents/ and the copies in ~/.cursor/agents/ and
#     ~/.gemini/agents/. A copy you
#     changed since is left in place. A file of yours that a helper replaced
#     is put back from its backup.
#   - the managed region in ~/.claude/CLAUDE.md and ~/.gemini/GEMINI.md
#     (your other lines stay; a file left empty is removed)
#   - ~/.cursor/rules/personal-instructions.mdc (if it is the kit's wrapper)
#   - the hook, status line and MCP entries it added to your config files
#   - Claude Code user MCP servers it added (including the Atlassian MCP
#     server that earlier kit versions added by default)
# Every file is backed up to ~/.agent-kit-backups/<time>/ before it changes.
# It leaves ~/.agents/ itself (your shared.md and rules) and all backups.
# It cannot see Cursor's User Rules: delete the pasted rule there yourself.
set -euo pipefail

AGENTS="${AGENTS_HOME:-$HOME/.agents}"
STATE="$AGENTS/.kit-installed"
export AGENTS_HOME="$AGENTS"
export KIT_BACKUP_DIR="${KIT_BACKUP_DIR:-$HOME/.agent-kit-backups/$(date +%Y%m%d-%H%M%S)-uninstall}"
HERE="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
BEGIN="<!-- managed-by: wire-personal-agents -->"
END="<!-- /managed-by: wire-personal-agents -->"
GEMINI_HEADER="# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict."

PREVIEW_ONLY=0; YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) PREVIEW_ONLY=1 ;;
    -y|--yes) YES=1 ;;
    -h|--help) sed -n '2,/^set -euo pipefail$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done
[[ -f "$STATE" ]] || { echo "Nothing recorded in $STATE; nothing to undo."; exit 0; }

say() { echo "  $*"; }
sumof() { cksum <"$1" | awk '{ print $1 "-" $2 }'; }
# restore <backup> <path>: put a backup back; a link comes back as a link.
restore() {
  mkdir -p "$(dirname "$2")"
  if [[ -L "$1" ]]; then ln -s "$(readlink "$1")" "$2"; else cp -p "$1" "$2"; fi
}
backup_file() {
  local f="$1" rel
  [[ -f "$f" ]] || return 0
  rel="${f#"$HOME"/}"; rel="${rel#/}"
  mkdir -p "$KIT_BACKUP_DIR/$(dirname "$rel")"; chmod 700 "$KIT_BACKUP_DIR"
  cp -p "$f" "$KIT_BACKUP_DIR/$rel"
  say "backed up $f -> $KIT_BACKUP_DIR/$rel"
}

strip_region() {  # strip_region <file>
  local f="$1" tmp
  [[ -f "$f" ]] && grep -qxF "$BEGIN" "$f" || return 0
  if (( DRY )); then say "would: remove the kit region from $f"; return 0; fi
  tmp="$(mktemp)"
  # Also drop the one blank line the wire script put before the region, so an
  # install/uninstall cycle leaves the file as it was.
  awk -v b="$BEGIN" -v e="$END" -v h="$GEMINI_HEADER" '
    skip { if ($0 == e) skip=0; next }
    $0 == b { held=0; skip=1; next }
    $0 == h { next }
    held { print ""; held=0 }
    $0 == "" { held=1; next }
    { print }
    END { if (held) print "" }' "$f" >"$tmp"
  backup_file "$f"
  if grep -q '[^[:space:]]' "$tmp"; then cat "$tmp" >"$f"; say "removed the kit region from $f"
  else rm -f "$f"; say "removed $f (only the kit region was in it)"; fi
  rm -f "$tmp"
}

steps() {
  local kind a b c d done_helpers=$'\n'
  while IFS=$'\t' read -r kind a b c d _; do
    if [[ "$kind" == link && -L "$a" && "$(readlink "$a")" == "$b" ]]; then
      if (( DRY )); then say "would: remove link $a"; else rm "$a"; say "removed link $a"; fi
    elif [[ "$kind" == helper && -L "$a" && "$(readlink "$a")" == "$b" ]]; then
      # A helper link that replaced a file of yours: put yours back.
      case "$done_helpers" in *$'\n'"$a"$'\n'*) continue ;; esac
      done_helpers="$done_helpers$a"$'\n'
      if (( DRY )); then say "would: remove link $a and restore yours from $c"; continue; fi
      rm "$a"
      if [[ -L "$c" ]]; then ln -s "$(readlink "$c")" "$a"; say "removed link $a and restored your link from $c"
      elif [[ -n "$c" && -e "$c" ]]; then cp -p "$c" "$a"; say "removed link $a and restored yours from $c"
      else say "removed link $a (backup $c not found; nothing to restore)"; fi
    elif [[ "$kind" == helper-copy ]]; then
      # A helper copy (Cursor or Gemini format). Only the newest record counts.
      case "$done_helpers" in *$'\n'"$a"$'\n'*) continue ;; esac
      done_helpers="$done_helpers$a"$'\n'
      local have=0
      [[ "$c" != "-" ]] && { [[ -L "$c" ]] || [[ -e "$c" ]]; } && have=1
      if [[ -f "$a" && ! -L "$a" && "$(sumof "$a")" == "$d" ]]; then
        if (( DRY )); then
          if (( have )); then say "would: remove the helper copy $a and restore yours from $c"; else say "would: remove the helper copy $a"; fi
          continue
        fi
        rm "$a"
        if (( have )); then restore "$c" "$a"; say "removed the helper copy $a and restored yours from $c"
        else say "removed the helper copy $a"; fi
      elif [[ ! -e "$a" && ! -L "$a" ]]; then
        if (( have )); then
          if (( DRY )); then say "would: restore $a from $c (the helper copy is already gone)"; else restore "$c" "$a"; say "restored $a from $c"; fi
        fi
      else
        if (( have )); then say "left $a: it changed since the install. Your earlier file is in $c"
        else say "left $a: it changed since the install"; fi
      fi
    fi
  # Newest record first: if a helper replaced your file on more than one run,
  # the copy you had most recently is the one put back.
  done < <(awk '{ l[NR] = $0 } END { for (i = NR; i >= 1; i--) print l[i] }' "$STATE")
  # Claude mirror links that now point at a removed Cursor rule link.
  local l
  for l in "$HOME"/.claude/rules/*.md; do
    [[ -L "$l" && ! -e "$l" ]] || continue
    case "$(readlink "$l")" in "$HOME/.cursor/rules/"*) ;; *) continue ;; esac
    if (( DRY )); then say "would: remove broken mirror link $l"; else rm "$l"; say "removed mirror link $l"; fi
  done
  strip_region "$HOME/.claude/CLAUDE.md"
  strip_region "$HOME/.gemini/GEMINI.md"
  local mdc="$HOME/.cursor/rules/personal-instructions.mdc"
  if [[ -f "$mdc" ]] && grep -qF "managed-by: wire-personal-agents" "$mdc"; then
    if (( DRY )); then say "would: remove $mdc"; else backup_file "$mdc"; rm "$mdc"; say "removed $mdc"; fi
  fi
  local pargs=(remove); (( DRY )) && pargs+=(--dry-run)
  python3 "$HERE/kit_config.py" "${pargs[@]}" || CONFIG_LEFT=1
  while IFS=$'\t' read -r kind a _; do
    [[ "$kind" == claude-mcp ]] || continue
    if [[ "$a" == atlassian ]]; then
      # The Atlassian server earlier kits added: only when it is still the kit's value.
      case "$(python3 "$HERE/kit_config.py" claude-mcp atlassian 2>/dev/null)" in
        kit) ;;
        gone) continue ;;
        yours) say "kept Claude Code MCP 'atlassian': you changed it since the kit added it"; continue ;;
        *) say "could not read Claude Code's config (.claude.json, or .config.json in its config folder); left MCP 'atlassian' alone (remove it by hand: claude mcp remove --scope user atlassian)"; continue ;;
      esac
    fi
    if ! command -v claude >/dev/null 2>&1; then say "claude CLI not found; remove MCP '$a' by hand: claude mcp remove --scope user $a"; continue; fi
    if (( DRY )); then say "would: claude mcp remove --scope user $a"
    elif claude mcp remove --scope user "$a" >/dev/null 2>&1; then say "removed Claude Code MCP '$a'"
    else say "could not remove Claude Code MCP '$a'; run: claude mcp remove --scope user $a"; fi
  done <"$STATE"
}

echo "== Preview: nothing has changed yet =="
DRY=1; CONFIG_LEFT=0; steps
(( PREVIEW_ONLY )) && { echo; echo "Dry run only."; exit 0; }
if (( ! YES )); then
  if [[ -t 0 ]]; then read -r -p "Undo these changes? [y/N] " r; case "$r" in y|Y|yes|YES) ;; *) echo "Nothing changed."; exit 0 ;; esac
  else echo "No terminal to confirm on. Re-run with --yes." >&2; exit 1; fi
fi
echo; echo "== Undoing =="
DRY=0; CONFIG_LEFT=0; steps
if (( CONFIG_LEFT )); then
  # kit_config.py kept the entries it could not remove in $STATE; keep the
  # file so a re-run after you fix the SKIPPED file finishes the job.
  echo
  echo "Some config entries were left (see SKIPPED above). Fix that file, then re-run this script."
  exit 3
fi
mv "$STATE" "$STATE.removed-$(date +%Y%m%d-%H%M%S)"
echo
echo "Done. Left in place: $AGENTS (delete it yourself if you want: rm -rf ~/.agents) and backups in ~/.agent-kit-backups/."
echo "If you pasted the kit's text into Cursor's User Rules, delete it there (Customize > Rules > User Rules)."
