#!/usr/bin/env python3
"""Merge the kit's entries into (or remove them from) your tool config files.

Files it touches (only for the tools you pick):
  Cursor       ~/.cursor/hooks.json, ~/.cursor/mcp.json
  Claude Code  ~/.claude/settings.json
  Gemini CLI   ~/.gemini/settings.json

Rules it follows:
  - Adds an entry only when it is missing. Never replaces a value you set
    (an existing statusLine or an MCP server with the same name is kept).
  - Backs up every file before it changes it (KIT_BACKUP_DIR).
  - Writes nothing when nothing would change, so re-runs are no-ops.
  - Never prints values from your files, only file paths and key names.
  - A file it cannot parse as plain JSON (for example JSON with comments) is
    left alone and reported.
  - Records what it added in ~/.agents/.kit-installed so uninstall.sh removes
    only those entries.

Usage:
  python3 kit_config.py merge  [--dry-run] [--tools=claude,cursor,gemini] [--no-mcp]
  python3 kit_config.py remove [--dry-run]
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import shutil
import sys
import tempfile
import time

HOME = os.path.expanduser("~")
KIT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENTS = os.environ.get("AGENTS_HOME", os.path.join(HOME, ".agents"))
STATE = os.path.join(AGENTS, ".kit-installed")
BACKUP_DIR = os.environ.get("KIT_BACKUP_DIR") or os.path.join(
    HOME, ".agent-kit-backups", time.strftime("%Y%m%d-%H%M%S")
)
SKILLS_REF = os.environ.get("KIT_SKILLS_REF", "main")  # tag or main, never a feature branch

CURSOR_HOOKS = os.path.join(HOME, ".cursor", "hooks.json")
CURSOR_MCP = os.path.join(HOME, ".cursor", "mcp.json")
CLAUDE_SETTINGS = os.path.join(HOME, ".claude", "settings.json")
GEMINI_SETTINGS = os.path.join(HOME, ".gemini", "settings.json")

ATLASSIAN_URL = "https://mcp.atlassian.com/v1/mcp"


def skills_server() -> dict:
    return {
        "command": "uvx",
        "args": [
            "--from",
            "git+https://github.com/urbn/r15-tech-skills.git@%s#subdirectory=mcp-server" % SKILLS_REF,
            "nuuly-tech-skills-mcp",
        ],
    }


def mcp_servers(want_skills: bool) -> dict:
    """The only MCP servers the installer adds: no tokens, no placeholders."""
    servers = {"atlassian": {"type": "http", "url": ATLASSIAN_URL}}  # OAuth; same shape for Cursor and Gemini
    if want_skills:
        servers["nuuly-skills"] = skills_server()
    return servers


def load_example(name: str) -> dict:
    with open(os.path.join(KIT, name), encoding="utf-8") as fh:
        data = json.load(fh)
    data.pop("_comment", None)
    return data


def short(path: str) -> str:
    return "~" + path[len(HOME):] if path.startswith(HOME + os.sep) else path


# ---------- state file (what the kit added) ----------

def read_state() -> list[list[str]]:
    if not os.path.exists(STATE):
        return []
    with open(STATE, encoding="utf-8") as fh:
        return [ln.rstrip("\n").split("\t") for ln in fh if ln.strip()]


def write_state(rows: list[list[str]]) -> None:
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    seen, out = set(), []
    for r in rows:
        key = "\t".join(r)
        if key not in seen:
            seen.add(key)
            out.append(key)
    with open(STATE, "w", encoding="utf-8") as fh:
        fh.write("".join(line + "\n" for line in out))


# ---------- file IO ----------

class Skip(Exception):
    pass


def load_json(path: str) -> dict | None:
    if not os.path.exists(path):
        return None
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except OSError as exc:
        raise Skip("cannot read (%s)" % exc.__class__.__name__)
    if not text.strip():
        return {}
    try:
        data = json.loads(text)
    except ValueError:
        raise Skip("not plain JSON (comments or trailing commas?)")
    if not isinstance(data, dict):
        raise Skip("top level is not a JSON object")
    return data


def backup(path: str) -> str:
    rel = os.path.relpath(path, HOME) if path.startswith(HOME + os.sep) else path.lstrip(os.sep)
    dest = os.path.join(BACKUP_DIR, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    os.chmod(BACKUP_DIR, 0o700)
    shutil.copy2(path, dest)
    return dest


def save_json(path: str, data: dict) -> None:
    existed = os.path.exists(path)
    if existed:
        print("  backed up %s -> %s" % (short(path), short(backup(path))))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".kit-")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    if existed:
        shutil.copymode(path, tmp)
    else:
        os.chmod(tmp, 0o600)
    os.replace(tmp, path)


# ---------- merge steps; each returns a list of (description, state-row) ----------

def merge_cursor_hooks(data: dict) -> list:
    changes = []
    example = load_example("hooks.example.json")
    data.setdefault("version", example.get("version", 1))
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise Skip("'hooks' is not an object")
    for event, entries in example["hooks"].items():
        lst = hooks.setdefault(event, [])
        if not isinstance(lst, list):
            raise Skip("'hooks.%s' is not a list" % event)
        for entry in entries:
            if any(isinstance(e, dict) and e.get("command") == entry["command"] for e in lst):
                continue
            lst.append(copy.deepcopy(entry))
            changes.append(("add hooks.%s: %s" % (event, entry["command"]),
                            ["json", CURSOR_HOOKS, "cursor-hook", event, entry["command"]]))
    return changes


def claude_has_command(groups: list, command: str) -> bool:
    for g in groups:
        if isinstance(g, dict):
            for h in g.get("hooks", []) or []:
                if isinstance(h, dict) and h.get("command") == command:
                    return True
    return False


def merge_claude_settings(data: dict) -> list:
    changes = []
    example = load_example("claude-settings.example.json")
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise Skip("'hooks' is not an object")
    for event, groups in example["hooks"].items():
        lst = hooks.setdefault(event, [])
        if not isinstance(lst, list):
            raise Skip("'hooks.%s' is not a list" % event)
        for group in groups:
            for h in group["hooks"]:
                if claude_has_command(lst, h["command"]):
                    continue
                lst.append({"hooks": [copy.deepcopy(h)]})
                changes.append(("add hooks.%s: %s" % (event, h["command"]),
                                ["json", CLAUDE_SETTINGS, "claude-hook", event, h["command"]]))
    want = example.get("statusLine")
    if want:
        if "statusLine" not in data:
            data["statusLine"] = copy.deepcopy(want)
            changes.append(("add statusLine: %s" % want["command"],
                            ["json", CLAUDE_SETTINGS, "statusline", "statusLine", want["command"]]))
        elif data["statusLine"] != want:
            print("  note: %s already has a statusLine; kept yours" % short(CLAUDE_SETTINGS))
    return changes


def merge_mcp(path: str, want_skills: bool):
    def step(data: dict) -> list:
        changes = []
        servers = data.setdefault("mcpServers", {})
        if not isinstance(servers, dict):
            raise Skip("'mcpServers' is not an object")
        for name, cfg in mcp_servers(want_skills).items():
            if name in servers:
                if servers[name] != cfg:
                    print("  note: %s already has an MCP server named '%s'; kept yours" % (short(path), name))
                continue
            servers[name] = copy.deepcopy(cfg)
            changes.append(("add mcpServers.%s" % name, ["json", path, "mcp", name, ""]))
        return changes
    return step


def apply(path: str, step, dry: bool, state: list) -> int:
    """Run one merge step against one file. Returns 1 when the file was skipped."""
    try:
        data = load_json(path)
        new = {} if data is None else copy.deepcopy(data)
        changes = step(new)
    except Skip as why:
        print("  SKIPPED %s: %s. Left it alone; see README 'Merge by hand'." % (short(path), why))
        return 1
    if not changes:
        print("  ok      %s (already has the kit entries)" % short(path))
        return 0
    verb = "would update" if dry else "update"
    if data is None:
        verb = "would create" if dry else "create"
    print("  %-7s %s" % (verb, short(path)))
    for desc, _ in changes:
        print("            - %s" % desc)
    if not dry:
        save_json(path, new)
        state.extend(row for _, row in changes)
    return 0


def do_merge(args) -> int:
    tools = set(args.tools.split(","))
    want_skills = shutil.which("uvx") is not None
    if args.mcp and not want_skills:
        print("  note: 'uvx' not found, so the nuuly-skills MCP server is not added. Install uv, then re-run.")
    state = read_state()
    skipped = 0
    if "cursor" in tools:
        skipped += apply(CURSOR_HOOKS, merge_cursor_hooks, args.dry_run, state)
        if args.mcp:
            skipped += apply(CURSOR_MCP, merge_mcp(CURSOR_MCP, want_skills), args.dry_run, state)
    if "claude" in tools:
        skipped += apply(CLAUDE_SETTINGS, merge_claude_settings, args.dry_run, state)
    if "gemini" in tools and args.mcp:
        skipped += apply(GEMINI_SETTINGS, merge_mcp(GEMINI_SETTINGS, want_skills), args.dry_run, state)
    if not args.dry_run:
        write_state(state)
    return 3 if skipped else 0


# ---------- remove ----------

def do_remove(args) -> int:
    rows = [r for r in read_state() if r and r[0] == "json"]
    keep = [r for r in read_state() if not (r and r[0] == "json")]
    by_file: dict[str, list] = {}
    for r in rows:
        by_file.setdefault(r[1], []).append(r)
    skipped = 0
    for path, items in by_file.items():
        try:
            data = load_json(path)
        except Skip as why:
            print("  SKIPPED %s: %s" % (short(path), why))
            skipped += 1
            keep.extend(items)
            continue
        if data is None:
            continue
        new = copy.deepcopy(data)
        done = []
        for _, _, kind, key, value in items:
            if kind == "cursor-hook":
                lst = new.get("hooks", {}).get(key, [])
                kept = [e for e in lst if not (isinstance(e, dict) and e.get("command") == value)]
                if len(kept) != len(lst):
                    new["hooks"][key] = kept
                    if not kept:
                        del new["hooks"][key]
                    done.append("remove hooks.%s: %s" % (key, value))
            elif kind == "claude-hook":
                lst = new.get("hooks", {}).get(key, [])
                kept = []
                for g in lst:
                    if isinstance(g, dict) and isinstance(g.get("hooks"), list):
                        hs = [h for h in g["hooks"] if not (isinstance(h, dict) and h.get("command") == value)]
                        if not hs:
                            continue
                        g = dict(g, hooks=hs)
                    kept.append(g)
                if kept != lst:
                    new["hooks"][key] = kept
                    if not kept:
                        del new["hooks"][key]
                    done.append("remove hooks.%s: %s" % (key, value))
            elif kind == "statusline":
                sl = new.get("statusLine")
                if isinstance(sl, dict) and sl.get("command") == value:
                    del new["statusLine"]
                    done.append("remove statusLine")
            elif kind == "mcp":
                servers = new.get("mcpServers", {})
                if key in servers:
                    del servers[key]
                    done.append("remove mcpServers.%s" % key)
                    if not servers:
                        del new["mcpServers"]
        if not done:
            print("  ok      %s (no kit entries left)" % short(path))
            continue
        print("  %-7s %s" % ("would update" if args.dry_run else "update", short(path)))
        for d in done:
            print("            - %s" % d)
        if not args.dry_run:
            save_json(path, new)
    if not args.dry_run:
        write_state(keep)
    return 3 if skipped else 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("action", choices=["merge", "remove"])
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--tools", default="claude,cursor,gemini")
    p.add_argument("--no-mcp", dest="mcp", action="store_false")
    args = p.parse_args()
    return do_merge(args) if args.action == "merge" else do_remove(args)


if __name__ == "__main__":
    sys.exit(main())
