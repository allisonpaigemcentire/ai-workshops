#!/usr/bin/env bash
# postToolUse hook — nudge once when a session exceeds turn/cost thresholds.
# Reads an optional hook event log (Span WAL) via session_cost_lib.py; fails open
# on any error, and stays silent when no log exists.

set -euo pipefail

input=$(cat)
export HOOK_INPUT="$input"
export HOOK_MARKER_DIR="${TMPDIR:-/tmp}/agent-cost-guard"
export HOOK_LIB="$HOME/.cursor/hooks/session_cost_lib.py"

mkdir -p "$HOOK_MARKER_DIR"

python3 << 'PY' || exit 0
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.environ["HOOK_LIB"]))
from session_cost_lib import (
    WARN_INPUT,
    WARN_TURNS,
    extract_session_id,
    format_cost,
    format_input,
    get_session_stats,
)

try:
    hook_input = json.loads(os.environ["HOOK_INPUT"])
except json.JSONDecodeError:
    sys.exit(0)

session_id = extract_session_id(hook_input)
if not session_id:
    sys.exit(0)

stats = get_session_stats(session_id)
if stats is None:
    sys.exit(0)

if stats.turns <= WARN_TURNS and stats.total_input < WARN_INPUT:
    sys.exit(0)

marker_dir = Path(os.environ["HOOK_MARKER_DIR"])
marker = marker_dir / session_id
if marker.exists():
    sys.exit(0)

cost_str = format_cost(stats.estimated_cost_usd)
input_str = format_input(stats.total_input)
msg = (
    f"Cost guardrail: this chat is large ({stats.turns} agent turns, "
    f"~{input_str} cumulative input tokens, ~{cost_str} est. at API list rates). "
    "Start a fresh chat when the task changes "
    "to avoid re-sending accumulated context on every turn."
)

marker.write_text("1")
print(json.dumps({"additional_context": msg}))
PY
