#!/usr/bin/env python3
"""Cursor stop hook: nudge session-memory wrap-up after corrections (capped).

Fails open. Never invents or writes lessons, only optionally returns
followup_message so the agent runs the session-memory skill.
"""

from __future__ import annotations

import json
import re
import os
import sys
from pathlib import Path

MAX_PROMPT_ATTEMPTS = 2
MEMORY_ROOT = Path.home() / ".ai-memory"
HOOKS_ROOT = MEMORY_ROOT / ".hooks"
SAFE_ID = re.compile(r"^[A-Za-z0-9_-][A-Za-z0-9._-]{0,127}$")

FOLLOWUP = (
    "A correction was marked earlier in this chat and session memory was not "
    "updated yet. Run the session-memory skill now: read "
    "~/.agents/skills/session-memory/SKILL.md, capture durable lessons into "
    "~/.ai-memory/, refresh MEMORY.md, and clear the needs-wrapup marker for "
    "this conversation. Do not invent lessons. Only store what the user "
    "corrected or confirmed."
)


def _conversation_id(payload: dict) -> str | None:
    for key in (
        "conversation_id",
        "conversationId",
        "session_id",
        "sessionId",
        "chat_id",
        "chatId",
        "composerId",
        "composer_id",
    ):
        value = payload.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    # Nested common shapes
    for nest in ("conversation", "session", "composer"):
        block = payload.get(nest)
        if isinstance(block, dict):
            for key in ("id", "conversation_id", "session_id"):
                value = block.get(key)
                if isinstance(value, str) and value.strip():
                    return value.strip()
    return None


def _read_attempts(conv_dir: Path) -> int:
    path = conv_dir / "prompt-attempts"
    if not path.is_file():
        return 0
    try:
        return int(path.read_text(encoding="utf-8").strip() or "0")
    except (OSError, ValueError):
        return 0


def _bump_attempts(conv_dir: Path) -> None:
    conv_dir.mkdir(parents=True, exist_ok=True)
    attempts = _read_attempts(conv_dir) + 1
    (conv_dir / "prompt-attempts").write_text(f"{attempts}\n", encoding="utf-8")


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        print("{}")
        return 0

    if not isinstance(payload, dict):
        print("{}")
        return 0

    status = payload.get("status") or "completed"
    if status != "completed":
        print("{}")
        return 0

    try:
        loop_count = int(payload.get("loop_count") or 0)
    except (TypeError, ValueError):
        loop_count = 0
    if loop_count >= 1:
        # Already in a follow-up loop from a prior nudge: stay quiet.
        print("{}")
        return 0

    conv_id = _conversation_id(payload)
    # The id becomes a folder name under ~/.ai-memory/.hooks; refuse anything
    # that could point outside it (a slash, "..", a leading dot).
    if not conv_id or not SAFE_ID.match(conv_id):
        print("{}")
        return 0

    conv_dir = HOOKS_ROOT / conv_id
    needs = conv_dir / "needs-wrapup"
    wrapped = conv_dir / "wrapped-up"

    if wrapped.is_file() or not needs.is_file():
        print("{}")
        return 0

    if _read_attempts(conv_dir) >= MAX_PROMPT_ATTEMPTS:
        print("{}")
        return 0

    try:
        _bump_attempts(conv_dir)
    except OSError:
        print("{}")
        return 0

    print(json.dumps({"followup_message": FOLLOWUP}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:  # noqa: BLE001 (hooks must fail open)
        print("{}")
        raise SystemExit(0)
