#!/usr/bin/env bash
# Installs the sample context-checker subagent (deck slide 5).
# Writes only ~/.agents/agents/context-checker.md (an existing copy, edited
# or not, is kept) and links it into ~/.cursor/agents/ and ~/.claude/agents/.
# A real file or someone else's link at a link path is skipped, never
# replaced. Safe to re-run. No network.
set -eu
src="$(cd "$(dirname "$0")" && pwd)/context-checker.md"
dst="$HOME/.agents/agents/context-checker.md"
mkdir -p "$HOME/.agents/agents" "$HOME/.cursor/agents" "$HOME/.claude/agents"
[ -e "$dst" ] || cp "$src" "$dst"
for f in "$HOME/.cursor/agents/context-checker.md" "$HOME/.claude/agents/context-checker.md"; do
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then ln -s "$dst" "$f"
  elif [ "$(readlink "$f" || true)" != "$dst" ]; then echo "Skipped $f: it is already there and is not the kit's link"; fi
done
ls -la "$HOME/.cursor/agents/context-checker.md" "$HOME/.claude/agents/context-checker.md"
