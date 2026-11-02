#!/usr/bin/env bash
# Cursor stop hook wrapper: session-memory wrap-up nudge (fail open).
set -euo pipefail
exec python3 "$HOME/.cursor/hooks/session-memory-stop.py"
