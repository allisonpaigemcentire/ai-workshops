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
#   --with-helpers                 also install the optional read-only subagents
#                                  code-reader and doc-reader for each tool in
#                                  --tools (see step 5)
#   --print-user-rule              print the text to paste into Cursor's User
#                                  Rules, then exit (use it after editing
#                                  shared.md)
#   --no-clipboard                 on macOS, do not copy that text with pbcopy
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
#      ~/.gemini/GEMINI.md and, as the Cursor fallback,
#      ~/.cursor/rules/personal-instructions.mdc. Existing CLAUDE.md /
#      GEMINI.md keep their lines; the kit adds one marked region.
#   4. Merges hooks, the status line and MCP servers into ~/.cursor/hooks.json,
#      ~/.cursor/mcp.json, ~/.claude/settings.json, ~/.gemini/settings.json,
#      and (if the claude CLI is installed) Claude Code's user MCP list.
#      Adds only what is missing; never replaces your values.
#   5. Only with --with-helpers, for each tool in --tools:
#      Claude Code: links code-reader.md and doc-reader.md into ~/.claude/agents/
#      Cursor:      copies examples/agents/cursor/*.md into ~/.cursor/agents/
#      Gemini CLI:  copies examples/agents/gemini/*.md into ~/.gemini/agents/
#                   (copies, not links: Gemini skips linked agent files)
#      A file or link of yours with the same name is backed up, then replaced;
#      uninstall puts it back. Later runs keep the kit's copies current
#      and leave alone a copy you changed.
#   Last, for Cursor: prints the text to paste into Customize > Rules >
#   User Rules (the main Cursor path), and on macOS copies it with pbcopy.
#
# Every file is backed up to ~/.agent-kit-backups/<time>/ before it changes.
# Re-running is safe: an unchanged setup produces no writes and no backups.
# Undo: bash ~/.agents/scripts/uninstall.sh
set -euo pipefail

KIT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
[[ -f "$KIT/scripts/kit_config.py" ]] || { echo "Run this from the kit: bash <kit>/scripts/install.sh (not through a symlink)" >&2; exit 1; }
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
HELPERS=0
HELPER_NAMES="code-reader.md doc-reader.md"
PRINT_RULE=0
CLIP=1
TOOLS="claude,cursor,gemini"
for arg in "$@"; do
  case "$arg" in
    --dry-run) PREVIEW_ONLY=1 ;;
    -y|--yes) YES=1 ;;
    --no-mcp) MCP=0 ;;
    --tools=*) TOOLS="${arg#--tools=}" ;;
    --with-helpers) HELPERS=1 ;;
    --print-user-rule) PRINT_RULE=1 ;;
    --no-clipboard) CLIP=0 ;;
    -h|--help) sed -n '2,/^set -euo pipefail$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done
case ",$TOOLS," in *,claude,*|*,cursor,*|*,gemini,*) ;; *) echo "--tools needs claude, cursor and/or gemini" >&2; exit 2 ;; esac
for t in ${TOOLS//,/ }; do
  case "$t" in claude|cursor|gemini) ;; *) echo "Unknown tool: $t (supported: claude,cursor,gemini)" >&2; exit 2 ;; esac
done
want() { [[ ",$TOOLS," == *",$1,"* ]]; }

# The text for Cursor's User Rules: shared.md without the template's leading
# comment block. Cursor does not read a file named in a User Rule on its own,
# so the rule holds the full text.
user_rule_text() {
  local shared="$AGENTS/instructions/shared.md"
  [[ -f "$shared" ]] || shared="$KIT/instructions/shared.template.md"
  awk 'BEGIN { lead = 1 }
    lead && /^[[:space:]]*$/ { next }
    lead && /^[[:space:]]*<!--/ { inc = 1 }
    inc { if (/-->/) inc = 0; next }
    { lead = 0; print }' "$shared"
}

print_user_rule() {
  local text
  text="$(user_rule_text)"
  echo "Cursor (main path): open Customize > Rules > User Rules (in older Cursor"
  echo "versions: Cursor Settings > Rules > User Rules), paste everything between"
  echo "the two marker lines below, and save. It applies to every project."
  echo "----- BEGIN CURSOR USER RULE -----"
  printf '%s\n' "$text"
  echo "----- END CURSOR USER RULE -----"
  if (( CLIP )) && [[ "$(uname -s 2>/dev/null)" == Darwin ]] && command -v pbcopy >/dev/null 2>&1; then
    if printf '%s\n' "$text" | pbcopy 2>/dev/null; then
      echo "Also copied to your clipboard (skip that with --no-clipboard)."
    else
      echo "Could not copy to the clipboard; copy the text above instead."
    fi
  fi
  echo "After you edit shared.md, paste it again. To print it again:"
  echo "  bash $AGENTS/scripts/install.sh --print-user-rule"
}

if (( PRINT_RULE )); then
  print_user_rule
  exit 0
fi

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
  # The two example JSONs are read by scripts/kit_config.py, so the copy in
  # ~/.agents/scripts/ can re-run the install on its own. The optional helpers
  # (examples/agents) are copied with --with-helpers, and kept current on
  # later runs once they are in ~/.agents.
  local extra=""
  if (( HELPERS )) || [[ -d "$AGENTS/examples/agents" ]]; then extra="examples/agents"; fi
  # shellcheck disable=SC2086  # $extra is empty or one path on purpose
  while IFS= read -r rel; do
    dest="$AGENTS/$rel"
    if [[ ! -e "$dest" ]]; then
      if (( DRY )); then say "would copy $rel"; else mkdir -p "$(dirname "$dest")"; cp -p "$KIT/$rel" "$dest"; fi
      n=$((n + 1))
    else
      case "$rel" in
        scripts/*|hooks/*|statusline/*|examples/*|*.example.json)   # kit code: keep it current
          if ! cmp -s "$KIT/$rel" "$dest"; then
            if (( DRY )); then say "would: update $dest (old copy backed up)"; else backup_file "$dest"; cp -p "$KIT/$rel" "$dest"; fi
            n=$((n + 1))
          fi ;;
      esac   # instructions/ and rules/ are yours once copied: never overwritten
    fi
  done < <(cd "$KIT" && find instructions rules hooks scripts statusline hooks.example.json claude-settings.example.json $extra -type f ! -name '.DS_Store' ! -name '*.pyc' 2>/dev/null | sort)
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
  if want cursor && (( DRY )); then
    say "would: print the text to paste into Cursor's User Rules (the main Cursor path)."
    say "       ~/.cursor/rules/personal-instructions.mdc is kept as the fallback."
  fi
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

  echo "5. Optional read-only helpers (~/.claude/agents/, ~/.cursor/agents/, ~/.gemini/agents/)"
  local h refresh=0
  HELPER_CHANGES=0
  # Without the flag, only refresh kit copies an earlier --with-helpers run
  # put in place (never add new ones, never touch a file you changed).
  (( HELPERS )) || refresh=1
  for h in $HELPER_NAMES; do
    if want claude && (( HELPERS )); then helper "$h"; fi
    if want cursor; then helper_copy cursor "$h" "$HOME/.cursor/agents/$h" "$refresh"; fi
    if want gemini; then helper_copy gemini "$h" "$HOME/.gemini/agents/$h" "$refresh"; fi
  done
  if (( HELPER_CHANGES )); then :
  elif (( HELPERS )); then say "ok (helpers in place)"
  elif [[ -f "$STATE" ]] && grep -q '^helper' "$STATE"; then say "ok (installed helpers are current)"
  else say "skipped (add --with-helpers to install code-reader and doc-reader)"; fi
}

# helper <file name>: link one optional subagent into ~/.claude/agents/. A real
# file or a link of yours with the same name is backed up first, then replaced;
# the record lets uninstall.sh put it back.
helper() {
  local name="$1" target="$AGENTS/examples/agents/$1" dest="$HOME/.claude/agents/$1" rel bk
  if [[ ! -f "$KIT/examples/agents/$name" && ! -f "$target" ]]; then
    say "not found in this kit: examples/agents/$name (run the installer from the unzipped kit)"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  if [[ -L "$dest" && "$(readlink "$dest")" == "$target" ]]; then return 0; fi
  if [[ -d "$dest" && ! -L "$dest" ]]; then
    say "conflict (folder, left alone): $dest"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    HELPER_CHANGES=$((HELPER_CHANGES + 1))
    link "$target" "$dest"
    return 0
  fi
  HELPER_CHANGES=$((HELPER_CHANGES + 1))
  if (( DRY )); then say "would: back up your $dest, then replace it with a link to $target"; return 0; fi
  rel="${dest#"$HOME"/}"; bk="$KIT_BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$bk")"
  chmod 700 "$KIT_BACKUP_DIR"
  rm -f "$bk"
  # A link is kept as a link (BSD cp follows links unless -R is given, and
  # fails on a dangling one), so uninstall can put back exactly what was here.
  if [[ -L "$dest" ]]; then ln -s "$(readlink "$dest")" "$bk"; else cp -p "$dest" "$bk"; fi
  say "backed up $dest -> $bk"
  rm -f "$dest"
  ln -s "$target" "$dest"
  say "linked $dest (yours is restored by uninstall)"
  record helper "$dest" "$target" "$bk"
}

sumof() { cksum <"$1" | awk '{ print $1 "-" $2 }'; }

# Newest helper-copy record for a path: "<checksum><TAB><backup or ->".
last_copy() {
  [[ -f "$STATE" ]] || return 0
  awk -F'\t' -v d="$1" '$1 == "helper-copy" && $2 == d { s = $5; b = $4 }
    END { if (s != "") print s "\t" b }' "$STATE"
}

# helper_copy <tool> <file name> <dest> <refresh-only 0|1>: copy one optional
# subagent in the tool's own format. The record keeps a checksum of the copy,
# so a later run (and uninstall) can tell the kit's copy from a file you
# changed or put there yourself. Links are backed up as links (see helper).
helper_copy() {
  local tool="$1" name="$2" dest="$3" refresh="$4" bk last lastsum prevbk
  local src="$AGENTS/examples/agents/$tool/$name" ksrc="$KIT/examples/agents/$tool/$name"
  if [[ ! -f "$ksrc" ]]; then
    (( refresh )) && return 0
    say "not found in this kit: examples/agents/$tool/$name (run the installer from the unzipped kit)"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  if [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$ksrc" "$dest"; then return 0; fi
  if [[ -d "$dest" && ! -L "$dest" ]]; then
    (( refresh )) && return 0
    say "conflict (folder, left alone): $dest"
    CONFLICTS=$((CONFLICTS + 1))
    return 0
  fi
  last="$(last_copy "$dest")"
  lastsum="${last%%$'\t'*}"; prevbk="${last#*$'\t'}"
  # A backup of your file from an earlier run stays on the record, so
  # uninstall still puts it back. "-" means none (an empty field would shift
  # the tab-separated columns).
  [[ -n "$prevbk" ]] || prevbk="-"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    (( refresh )) && return 0
    HELPER_CHANGES=$((HELPER_CHANGES + 1))
    if (( DRY )); then say "would copy $dest (from $ksrc)"; return 0; fi
    mkdir -p "$(dirname "$dest")"
    cp "$ksrc" "$dest"
    say "copied $dest"
    record helper-copy "$dest" "$src" "$prevbk" "$(sumof "$dest")"
    return 0
  fi
  if [[ -n "$lastsum" && -f "$dest" && ! -L "$dest" && "$(sumof "$dest")" == "$lastsum" ]]; then
    # The kit's own copy from an earlier run, unchanged by you: update it.
    HELPER_CHANGES=$((HELPER_CHANGES + 1))
    if (( DRY )); then say "would: update $dest (the kit's copy changed)"; return 0; fi
    if [[ "$prevbk" == "$KIT_BACKUP_DIR/${dest#"$HOME"/}" ]]; then
      # Same backup folder as the run that saved your file (two runs in one
      # second): keep your file's backup, save the kit's old copy beside it.
      cp -p "$dest" "$prevbk.kit-copy"
      say "backed up $dest -> $prevbk.kit-copy"
    else
      backup_file "$dest"
    fi
    cp "$ksrc" "$dest"
    say "updated $dest"
    record helper-copy "$dest" "$src" "$prevbk" "$(sumof "$dest")"
    return 0
  fi
  if [[ -n "$lastsum" ]]; then
    # The kit put a copy here and you changed or replaced it since: yours now,
    # left alone even with --with-helpers (uninstall leaves it too).
    say "left $dest: you changed the kit's copy (to get the kit's copy back, delete it and re-run with --with-helpers)"
    return 0
  fi
  (( refresh )) && return 0   # yours: left alone without --with-helpers
  HELPER_CHANGES=$((HELPER_CHANGES + 1))
  if (( DRY )); then say "would: back up your $dest, then replace it with the kit's copy"; return 0; fi
  bk="$KIT_BACKUP_DIR/${dest#"$HOME"/}"
  mkdir -p "$(dirname "$bk")"
  chmod 700 "$KIT_BACKUP_DIR"
  rm -f "$bk"
  if [[ -L "$dest" ]]; then ln -s "$(readlink "$dest")" "$bk"; else cp -p "$dest" "$bk"; fi
  say "backed up $dest -> $bk"
  rm -f "$dest"
  cp "$ksrc" "$dest"
  say "copied $dest (yours is restored by uninstall)"
  record helper-copy "$dest" "$src" "$bk" "$(sumof "$dest")"
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
if want cursor; then
  echo
  print_user_rule
fi
cat <<MSG

Next:
  1. Fill in the <placeholders> in $AGENTS/instructions/shared.md, then re-run
     this installer (or: bash $AGENTS/scripts/wire-personal-agents.sh).
     For Cursor, paste the User Rule text again after each edit.
  2. Start a new chat in Cursor, Claude Code and Gemini CLI.
  3. MCP: Atlassian signs in with OAuth on first use. Token servers: see
     mcp.example.json; secrets go in env vars or the Keychain, never in files.
Check for drift any time:  bash $AGENTS/scripts/wire-personal-agents.sh --check
Undo:                      bash $AGENTS/scripts/uninstall.sh
MSG
