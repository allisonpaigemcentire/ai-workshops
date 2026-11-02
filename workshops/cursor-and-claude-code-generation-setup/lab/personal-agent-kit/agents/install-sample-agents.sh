#!/usr/bin/env bash
# Installs the three sample read-only subagents for Cursor and Claude Code:
# context-checker, code-reader and doc-reader.
#
#   bash ~/src/personal-agent-kit/agents/install-sample-agents.sh
#   bash ~/src/personal-agent-kit/agents/install-sample-agents.sh --dry-run
#   bash ~/src/personal-agent-kit/agents/install-sample-agents.sh --check
#
# It runs the kit installer's helpers-only mode, so it writes only:
#   ~/.agents/examples/agents/   the kit's agent files (and ~/.agents/scripts/
#                                so uninstall works)
#   ~/.claude/agents/<name>.md   a link to the file above
#   ~/.cursor/agents/<name>.md   a copy in Cursor's format (readonly: true)
# A file of yours with the same name is backed up first, then replaced, and
# uninstall puts it back. A kit copy you changed later is left alone. Safe to
# re-run: an unchanged setup produces no writes. No network.
# --check reports drift and changes nothing (exit 1 if an agent is missing
# or older than the kit's).
# Gemini CLI: not set up here. For code-reader and doc-reader in Gemini, run
#   bash <kit>/scripts/install.sh --with-helpers --tools=gemini
# Undo: bash ~/.agents/scripts/uninstall.sh
set -euo pipefail
here="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
install="$here/../scripts/install.sh"
[[ -f "$install" ]] || { echo "Run this from the unzipped kit: bash <kit>/agents/install-sample-agents.sh" >&2; exit 1; }
mode=(--helpers-only --yes)
for arg in "$@"; do
  case "$arg" in
    --check) mode=(--check-helpers) ;;
    --dry-run) mode=(--helpers-only --dry-run) ;;
    -h|--help) sed -n '2,/^set -euo pipefail$/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $arg (try --help)" >&2; exit 2 ;;
  esac
done
exec bash "$install" "${mode[@]}" --tools=claude,cursor
