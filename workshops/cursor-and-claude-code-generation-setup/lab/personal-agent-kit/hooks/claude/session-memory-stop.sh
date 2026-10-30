#!/usr/bin/env bash
# Claude Stop hook wrapper — session-memory wrap-up nudge (fail open).
set -euo pipefail
exec python3 "$HOME/.claude/hooks/session-memory-stop.py"
