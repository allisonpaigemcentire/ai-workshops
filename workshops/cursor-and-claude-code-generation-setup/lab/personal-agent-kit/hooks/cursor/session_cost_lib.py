#!/usr/bin/env python3
"""Shared session cost stats from a hook event log + pricing.json.

OPTIONAL DATA SOURCE: this reads the Span hook write-ahead log
(~/.span/wal/hooks-wal*.jsonl). If you do not run Span, get_session_stats()
returns None and the cost guard stays silent (fails open).
Override paths with SESSION_COST_WAL_GLOB and SESSION_COST_PRICING_FILE.
"""

import glob
import json
import os
from pathlib import Path

WAL_GLOB = os.path.expanduser(os.environ.get("SESSION_COST_WAL_GLOB", "~/.span/wal/hooks-wal*.jsonl"))
PRICING_FILE = Path(os.environ.get("SESSION_COST_PRICING_FILE", "~/.agents/hooks/pricing.json")).expanduser()

WARN_TURNS = 25
WARN_INPUT = 15_000_000
CRITICAL_TURNS = 40
CRITICAL_INPUT = 30_000_000


class SessionStats:
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.turns = 0
        self.total_input = 0
        self.total_output = 0
        self.cache_read = 0
        self.cache_write = 0
        self.estimated_cost_usd = None

    @property
    def net_new_input(self):
        return self.total_input - self.cache_read

    def warn_level(self):
        if self.turns >= CRITICAL_TURNS or self.total_input >= CRITICAL_INPUT:
            return "red"
        if self.turns >= WARN_TURNS or self.total_input >= WARN_INPUT:
            return "yellow"
        return "green"


def _load_pricing():
    if not PRICING_FILE.exists():
        return {}
    try:
        return json.loads(PRICING_FILE.read_text())["models"]
    except Exception:
        return {}


def _estimate_cost(pricing, model, inp, out, cache_r, cache_w):
    p = pricing.get(model)
    if not p:
        return None
    return (
        ((inp - cache_r) / 1_000_000) * p.get("input_per_million_usd", 0)
        + (out / 1_000_000) * p.get("output_per_million_usd", 0)
        + (cache_r / 1_000_000) * p.get("cache_read_per_million_usd", 0)
        + (cache_w / 1_000_000) * p.get("cache_write_per_million_usd", 0)
    )


def get_session_stats(session_id):
    if not session_id:
        return None

    pricing = _load_pricing()
    stats = SessionStats(session_id)
    cost_total = 0.0
    has_cost = False

    for wal_path in sorted(glob.glob(WAL_GLOB)):
        try:
            with open(wal_path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        row = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    evt = row.get("event", {})
                    if evt.get("event_type") != "after_agent_response":
                        continue
                    sid = evt.get("session_id") or evt.get("conversation_id", "")
                    if sid != session_id:
                        continue
                    model = evt.get("model", "unknown")
                    inp = int(evt.get("input_tokens") or 0)
                    out = int(evt.get("output_tokens") or 0)
                    cr = int(evt.get("cache_read_tokens") or 0)
                    cw = int(evt.get("cache_write_tokens") or 0)
                    stats.turns += 1
                    stats.total_input += inp
                    stats.total_output += out
                    stats.cache_read += cr
                    stats.cache_write += cw
                    c = _estimate_cost(pricing, model, inp, out, cr, cw)
                    if c is not None:
                        cost_total += c
                        has_cost = True
        except OSError:
            continue

    if stats.turns == 0:
        return None
    stats.estimated_cost_usd = cost_total if has_cost else None
    return stats


def extract_session_id(hook_input):
    for key in ("session_id", "conversation_id", "agent_session_id"):
        val = hook_input.get(key)
        if val:
            return str(val)
    return ""


def format_cost(cost):
    if cost is None:
        return "?"
    return f"${cost:.2f}"


def format_input(n):
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}K"
    return str(n)


def load_module(lib_path):
    import sys
    from importlib.util import module_from_spec, spec_from_file_location

    spec = spec_from_file_location("session_cost_lib", lib_path)
    mod = module_from_spec(spec)
    sys.modules["session_cost_lib"] = mod
    spec.loader.exec_module(mod)
    return mod
