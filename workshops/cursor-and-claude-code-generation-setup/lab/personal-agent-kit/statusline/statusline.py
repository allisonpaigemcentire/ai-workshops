# /// script
# requires-python = ">=3.12"
# dependencies = ["rich>=13.0"]
# ///
"""Claude Code status line: session + monthly usage, Tufte-style.

OPTIONAL, richer alternative to statusline-command.sh. Needs `uv` (runs as a
PEP 723 script: `uv run ~/.claude/statusline.py`) and the `rich` package.

Privacy note: to show the monthly spend cap it reads the Claude Code OAuth
access token that Claude Code itself stores in the macOS Keychain (or the
CLAUDE_ACCESS_TOKEN environment variable) and calls Anthropic's usage
endpoint. The token is used in memory only and never printed or written.
This is OFF unless STATUSLINE_ENTERPRISE_USAGE=1 is set.
"""

import datetime
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console
from rich.text import Text

CACHE_FILE = Path.home() / ".claude" / ".statusline-cache.json"
ENTERPRISE_TTL = 300  # 5 minutes
MONTHLY_TOKENS_TTL = 300  # 5 minutes between incremental updates
FULL_SCAN_INTERVAL = 86400  # 24 hours between full 30-day rescans
THIRTY_DAYS = 30 * 24 * 3600
EIGHTHS = "▁▂▃▄▅▆▇█"


# --- Cache ---


def load_cache() -> dict:
    try:
        return json.loads(CACHE_FILE.read_text())
    except Exception:
        return {}


def save_cache(cache: dict) -> None:
    try:
        CACHE_FILE.write_text(json.dumps(cache))
    except Exception:
        pass


# --- Enterprise API ---


def _get_oauth_token() -> str | None:
    """Retrieve the Anthropic OAuth access token.

    On macOS: reads from the Claude Code keychain entry.
    Fallback: CLAUDE_ACCESS_TOKEN environment variable (useful on Linux/CI).
    """
    if sys.platform == "darwin":
        try:
            creds_json = subprocess.run(
                ["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
                capture_output=True,
                text=True,
                timeout=5,
            ).stdout.strip()
            return json.loads(creds_json)["claudeAiOauth"]["accessToken"]
        except Exception:
            pass
    return os.environ.get("CLAUDE_ACCESS_TOKEN")


def get_enterprise_usage(cache: dict) -> dict | None:
    # Off by default in the shared kit: reading the stored OAuth credential is
    # opt-in. Set STATUSLINE_ENTERPRISE_USAGE=1 to show the monthly spend cap.
    if os.environ.get("STATUSLINE_ENTERPRISE_USAGE") != "1":
        return None
    entry = cache.get("enterprise", {})
    if time.time() - entry.get("ts", 0) < ENTERPRISE_TTL:
        return entry.get("data")

    token = _get_oauth_token()
    if not token:
        return None

    try:
        result = subprocess.run(
            [
                "curl",
                "-sf",
                "https://api.anthropic.com/api/oauth/usage",
                "-H",
                f"Authorization: Bearer {token}",
                "-H",
                "anthropic-beta: oauth-2025-04-20",
                "-H",
                "User-Agent: claude-code/statusline",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode != 0:
            return None
        data = json.loads(result.stdout)
        cache["enterprise"] = {"ts": time.time(), "data": data}
        return data
    except Exception:
        return None


# --- Token counting ---


def sum_tokens_in_file(path: Path) -> int:
    total = 0
    try:
        with open(path) as f:
            for line in f:
                try:
                    usage = (json.loads(line).get("message") or {}).get("usage") or {}
                    total += (
                        usage.get("input_tokens", 0)
                        + usage.get("cache_creation_input_tokens", 0)
                        + usage.get("cache_read_input_tokens", 0)
                        + usage.get("output_tokens", 0)
                    )
                except Exception:
                    pass
    except Exception:
        pass
    return total


def get_session_tokens(transcript_path: str | None) -> int:
    return sum_tokens_in_file(Path(transcript_path)) if transcript_path else 0


def get_monthly_tokens(cache: dict) -> int:
    now = time.time()
    entry = cache.get("monthly_tokens", {})
    cutoff_30d = now - THIRTY_DAYS
    projects = Path.home() / ".claude" / "projects"

    # Full rescan: no cache, or 24h since last full scan (maintains rolling-window accuracy)
    if not entry or (now - entry.get("full_scan_ts", 0)) > FULL_SCAN_INTERVAL:
        total = 0
        try:
            for jsonl in projects.rglob("*.jsonl"):
                if jsonl.stat().st_mtime >= cutoff_30d:
                    total += sum_tokens_in_file(jsonl)
        except Exception:
            pass
        cache["monthly_tokens"] = {
            "ts": now,
            "tokens": total,
            "scanned_through": now,
            "full_scan_ts": now,
        }
        return total

    # Within TTL: return cached total
    if now - entry.get("ts", 0) < MONTHLY_TOKENS_TTL:
        return entry.get("tokens", 0)

    # Incremental: only files newer than the last scan high-water mark
    scanned_through = entry.get("scanned_through", now)
    delta = 0
    try:
        for jsonl in projects.rglob("*.jsonl"):
            mtime = jsonl.stat().st_mtime
            if mtime > scanned_through and mtime >= cutoff_30d:
                delta += sum_tokens_in_file(jsonl)
    except Exception:
        pass

    new_total = entry.get("tokens", 0) + delta
    cache["monthly_tokens"] = {
        "ts": now,
        "tokens": new_total,
        "scanned_through": now,
        "full_scan_ts": entry.get("full_scan_ts", 0),
    }
    return new_total


# --- Visualization ---


def pct_to_eighth(pct: float) -> str:
    """Map 0–100 to a single eighth-block character (▁▂▃▄▅▆▇█)."""
    if pct <= 0:
        return " "
    return EIGHTHS[min(int(pct / 100 * 8), 7)]


def _get_ctx_pcts(transcript_path: str | None, ctx_size: int) -> list[float]:
    """Per-turn ctx fill % for every API response in the transcript."""
    if not transcript_path:
        return []
    pcts: list[float] = []
    try:
        with open(transcript_path) as f:
            for line in f:
                try:
                    usage = (json.loads(line).get("message") or {}).get("usage") or {}
                    if not usage:
                        continue
                    total_in = (
                        usage.get("input_tokens", 0)
                        + usage.get("cache_creation_input_tokens", 0)
                        + usage.get("cache_read_input_tokens", 0)
                    )
                    pcts.append(total_in / ctx_size * 100)
                except Exception:
                    pass
    except Exception:
        pass
    return pcts


def get_ctx_sparkline(pcts: list[float], n: int = 8) -> str:
    """Sparkline of the last n ctx fill percentages."""
    if len(pcts) < 2:
        return ""
    return "".join(pct_to_eighth(p) for p in pcts[-n:])


def fmt_tokens(n: int) -> str:
    if n >= 1_000_000_000:
        return f"{n / 1_000_000_000:.1f}B"
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def ctx_style(pct: float) -> str:
    if pct > 90:
        return "bold red"
    if pct > 70:
        return "bold yellow"
    return "bold green"


def cap_style(pct: float) -> str:
    if pct > 85:
        return "bold red"
    if pct > 60:
        return "bold yellow"
    return "bold green"


def cost_style(cost: float) -> str:
    """Escalate session cost color: yellow above $5, red above $10."""
    if cost > 10.0:
        return "bold red"
    if cost > 5.0:
        return "bold yellow"
    return ""


def billing_pace(used_cents: float) -> str:
    """Daily burn rate and days remaining for the current calendar-month billing period."""
    today = datetime.date.today()
    days_elapsed = today.day
    if days_elapsed == 0:
        return ""
    # Last day of current month
    first_of_next = (today.replace(day=1) + datetime.timedelta(days=32)).replace(day=1)
    days_in_month = (first_of_next - datetime.timedelta(days=1)).day
    days_remaining = days_in_month - days_elapsed
    daily_rate = used_cents / days_elapsed / 100  # in dollars
    return f"  {days_remaining}d rem  ${daily_rate:.1f}/d"


def model_label(data: dict) -> str:
    model_data = data.get("model") or {}
    model_id = model_data.get("id") or model_data.get("display_name") or "?"
    m = re.search(r"claude-(\w+)-(\d+)(?:-(\d+))?", model_id)
    if m:
        if m.group(3):
            return f"{m.group(1).capitalize()} {m.group(2)}.{m.group(3)}"
        return f"{m.group(1).capitalize()} {m.group(2)}"
    return model_data.get("display_name") or model_id


def model_style(data: dict) -> str:
    """Color the model label by family tier: Opus=magenta, Haiku=green, Sonnet=cyan."""
    model_id = ((data.get("model") or {}).get("id") or "").lower()
    if "opus" in model_id:
        return "bold magenta"
    if "haiku" in model_id:
        return "bold green"
    return "bold cyan"


# --- Main ---


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    cache = load_cache()

    ctx_size = int((data.get("context_window") or {}).get("context_window_size") or 200_000)
    ctx_pct = float((data.get("context_window") or {}).get("used_percentage") or 0)
    session_cost = float((data.get("cost") or {}).get("total_cost_usd") or 0)
    transcript_path = data.get("transcript_path")

    session_tok = get_session_tokens(transcript_path)
    monthly_tok = get_monthly_tokens(cache)
    usage = get_enterprise_usage(cache)
    ctx_pcts = _get_ctx_pcts(transcript_path, ctx_size)
    sparkline = get_ctx_sparkline(ctx_pcts)
    peak_pct = max(ctx_pcts) if ctx_pcts else 0.0

    t = Text()

    # Model — parsed from model.id for "Sonnet 5" format, colored by family tier
    t.append(model_label(data), style=model_style(data))

    # Session badge + ctx label + sparkline + glyph + %
    t.append("  ")
    t.append(" sess ", style="bold black on dark_goldenrod")
    t.append(" ctx ", style="dim")
    if sparkline:
        t.append(sparkline, style="dim")
        t.append(" ")
    t.append(pct_to_eighth(ctx_pct), style=ctx_style(ctx_pct))
    t.append(f" {ctx_pct:.0f}%", style=ctx_style(ctx_pct))

    # Peak ctx — only when the session high-water mark is >10% above current
    if peak_pct > ctx_pct + 10:
        t.append(" pk ", style="dim")
        t.append(pct_to_eighth(peak_pct), style=ctx_style(peak_pct))
        t.append(f" {peak_pct:.0f}%", style=ctx_style(peak_pct))

    # tok label + tokens + cost
    t.append("  tok ", style="dim")
    t.append(fmt_tokens(session_tok))
    t.append(f"  ${session_cost:.2f}", style=cost_style(session_cost))

    # Monthly badge
    t.append("  ")
    t.append(" mo ", style="bold black on steel_blue1")

    if usage and (extra := usage.get("extra_usage")) and extra.get("is_enabled"):
        used_cents = float(extra.get("used_credits") or 0)
        cap_cents = float(extra.get("monthly_limit") or 1)
        util_pct = used_cents / cap_cents * 100
        t.append(" cap ", style="dim")
        t.append(pct_to_eighth(util_pct), style=cap_style(util_pct))
        t.append(f" {util_pct:.0f}%", style=cap_style(util_pct))
        t.append("  tok ", style="dim")
        t.append(fmt_tokens(monthly_tok))
        t.append(f"  ${used_cents / 100:.2f}/${cap_cents / 100:.0f}")
        t.append(billing_pace(used_cents), style="dim")
    else:
        t.append(" tok ", style="dim")
        t.append(fmt_tokens(monthly_tok))

    save_cache(cache)
    Console(highlight=False, force_terminal=True).print(t, end="\n", soft_wrap=True)


if __name__ == "__main__":
    main()
