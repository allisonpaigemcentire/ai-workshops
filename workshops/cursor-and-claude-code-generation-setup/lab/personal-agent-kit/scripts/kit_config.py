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
  - Removes the Atlassian MCP server that earlier kit versions added, but
    only when the record says the kit added it and it is still exactly the
    kit's value. Jira and Confluence now go through Atlassian's CLI (acli).

Usage:
  python3 kit_config.py merge  [--dry-run] [--tools=claude,cursor,gemini] [--no-mcp]
  python3 kit_config.py remove [--dry-run]
  python3 kit_config.py claude-mcp <name>
      Prints one word about that server in Claude Code's user list:
      gone, kit (the old Atlassian value), yours, or unknown (unreadable).
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
# Optional team skills MCP server. Off unless both are set, for example
#   KIT_SKILLS_FROM='git+https://github.com/<org>/<repo>.git@main#subdirectory=<dir>'
#   KIT_SKILLS_ENTRY='<console-script-name>'
# Pin a tag or main in KIT_SKILLS_FROM, never a feature branch.
SKILLS_FROM = os.environ.get("KIT_SKILLS_FROM", "").strip()
SKILLS_ENTRY = os.environ.get("KIT_SKILLS_ENTRY", "").strip()
SKILLS_NAME = "team-skills"

CURSOR_HOOKS = os.path.join(HOME, ".cursor", "hooks.json")
CURSOR_MCP = os.path.join(HOME, ".cursor", "mcp.json")
CLAUDE_SETTINGS = os.path.join(HOME, ".claude", "settings.json")
GEMINI_SETTINGS = os.path.join(HOME, ".gemini", "settings.json")

# Earlier kit versions added this Atlassian MCP server by default. The kit now
# points agents at Atlassian's CLI (acli) instead, so merge removes the old
# entry (see retire_old_mcp) and nothing adds it.
OLD_ATLASSIAN_NAME = "atlassian"
OLD_ATLASSIAN = {"type": "http", "url": "https://mcp.atlassian.com/v1/mcp"}


# Claude Code keeps its user MCP list in .claude.json, under CLAUDE_CONFIG_DIR
# when that is set (checked with Claude Code 2.1), else in your home folder.
CLAUDE_JSON = os.path.join(os.environ.get("CLAUDE_CONFIG_DIR") or HOME, ".claude.json")


def skills_server() -> dict:
    return {"command": "uvx", "args": ["--from", SKILLS_FROM, SKILLS_ENTRY]}


def mcp_servers(want_skills: bool) -> dict:
    """The only MCP servers the installer adds: no tokens, no placeholders.

    None by default. Jira and Confluence use Atlassian's CLI (acli).
    """
    servers = {}
    if want_skills:
        servers[SKILLS_NAME] = skills_server()
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
    # Write through a symlink (dotfile managers link these files); replacing
    # the link itself would silently detach the file from its real copy.
    path = os.path.realpath(path)
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


def retire_old_mcp(path: str, dry: bool, state: list) -> int:
    """Remove the Atlassian MCP server an earlier kit version added to path.

    Only when the record shows the kit added it and the value is still the
    kit's own. A server you changed, or added yourself, is kept.
    Returns 1 when the file was skipped.
    """
    rows = [r for r in state if r[:4] == ["json", path, "mcp", OLD_ATLASSIAN_NAME]]
    if not rows:
        return 0
    try:
        data = load_json(path)
    except Skip as why:
        print("  SKIPPED %s: %s. Left the old '%s' MCP server alone." % (short(path), why, OLD_ATLASSIAN_NAME))
        return 1
    servers = (data or {}).get("mcpServers")
    if not isinstance(servers, dict) or OLD_ATLASSIAN_NAME not in servers:
        # Already gone: forget the record.
        if not dry:
            state[:] = [r for r in state if r not in rows]
        return 0
    if servers[OLD_ATLASSIAN_NAME] != OLD_ATLASSIAN:
        print("  note: %s has an MCP server named '%s' that you changed; kept yours."
              " Jira and Confluence now use acli, so you can remove it." % (short(path), OLD_ATLASSIAN_NAME))
        if not dry:
            state[:] = [r for r in state if r not in rows]
        return 0
    new = copy.deepcopy(data)
    del new["mcpServers"][OLD_ATLASSIAN_NAME]
    if not new["mcpServers"]:
        del new["mcpServers"]
    why = "added by an earlier kit; Jira and Confluence now use acli"
    created = ["json", path, "created", "", ""]
    if created in state and not new:
        # The kit created this file for that one server: remove the file.
        print("  %-7s %s (only the old '%s' MCP server was in it; %s)" % (
            "would remove" if dry else "remove", short(path), OLD_ATLASSIAN_NAME, why))
        if not dry:
            print("  backed up %s -> %s" % (short(path), short(backup(path))))
            os.remove(path)
            state[:] = [r for r in state if r not in rows and r != created]
        return 0
    print("  %-7s %s" % ("would update" if dry else "update", short(path)))
    print("            - remove mcpServers.%s (%s)" % (OLD_ATLASSIAN_NAME, why))
    if not dry:
        save_json(path, new)
        state[:] = [r for r in state if r not in rows]
    return 0


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
        if data is None:
            state.append(["json", path, "created", "", ""])
        state.extend(row for _, row in changes)
    return 0


def do_merge(args) -> int:
    tools = set(args.tools.split(","))
    want_skills = bool(SKILLS_FROM and SKILLS_ENTRY)
    if args.mcp and bool(SKILLS_FROM) != bool(SKILLS_ENTRY):
        print("  note: set both KIT_SKILLS_FROM and KIT_SKILLS_ENTRY to add the %s MCP server;"
              " only one is set, so it is not added." % SKILLS_NAME)
    if args.mcp and want_skills and shutil.which("uvx") is None:
        print("  note: 'uvx' not found, so the %s MCP server is not added. Install uv, then re-run." % SKILLS_NAME)
        want_skills = False
    state = read_state()
    skipped = 0
    # Clean up the old default Atlassian MCP server first, even with --no-mcp.
    if "cursor" in tools:
        skipped += retire_old_mcp(CURSOR_MCP, args.dry_run, state)
    if "gemini" in tools:
        skipped += retire_old_mcp(GEMINI_SETTINGS, args.dry_run, state)
    # Nothing to add unless the optional team-skills server is set up.
    add_mcp = args.mcp and bool(mcp_servers(want_skills))
    if "cursor" in tools:
        skipped += apply(CURSOR_HOOKS, merge_cursor_hooks, args.dry_run, state)
        if add_mcp:
            skipped += apply(CURSOR_MCP, merge_mcp(CURSOR_MCP, want_skills), args.dry_run, state)
    if "claude" in tools:
        skipped += apply(CLAUDE_SETTINGS, merge_claude_settings, args.dry_run, state)
    if "gemini" in tools and add_mcp:
        skipped += apply(GEMINI_SETTINGS, merge_mcp(GEMINI_SETTINGS, want_skills), args.dry_run, state)
    if not args.dry_run:
        write_state(state)
    return 3 if skipped else 0


# ---------- remove ----------

def _only_kit_scaffold(data: dict) -> bool:
    """True when only the empty containers the kit itself adds are left."""
    rest = dict(data)
    for key in ("hooks", "mcpServers"):
        if rest.get(key) == {}:
            del rest[key]
    if rest.get("version") == 1 and "hooks" in data:
        del rest["version"]
    return not rest


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
        created = False
        for row in items:
            if len(row) < 5:
                continue
            kind, key, value = row[2], row[3], row[4]
            if kind == "created":
                created = True
                continue
            hooks = new.get("hooks")
            if kind in ("cursor-hook", "claude-hook") and not isinstance(hooks, dict):
                continue
            if kind == "cursor-hook":
                lst = hooks.get(key, [])
                if not isinstance(lst, list):
                    continue
                kept = [e for e in lst if not (isinstance(e, dict) and e.get("command") == value)]
                if len(kept) != len(lst):
                    new["hooks"][key] = kept
                    if not kept:
                        del new["hooks"][key]
                    done.append("remove hooks.%s: %s" % (key, value))
            elif kind == "claude-hook":
                lst = hooks.get(key, [])
                if not isinstance(lst, list):
                    continue
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
                servers = new.get("mcpServers")
                if (key == OLD_ATLASSIAN_NAME and isinstance(servers, dict)
                        and key in servers and servers[key] != OLD_ATLASSIAN):
                    print("  note: %s has an MCP server named '%s' that you changed; kept yours."
                          % (short(path), key))
                    continue
                if isinstance(servers, dict) and key in servers:
                    del servers[key]
                    done.append("remove mcpServers.%s" % key)
                    if not servers:
                        del new["mcpServers"]
        if created and _only_kit_scaffold(new):
            # The kit created this file and nothing of yours is in it: remove it.
            print("  %-7s %s (the kit created it; nothing else is in it)" % (
                "would remove" if args.dry_run else "remove", short(path)))
            if not args.dry_run:
                print("  backed up %s -> %s" % (short(path), short(backup(path))))
                os.remove(path)
            continue
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


def claude_json() -> str:
    """The file Claude Code reads its user MCP list from (checked with 2.1.314):
    a non-empty legacy .config.json in its config folder wins over .claude.json.
    Claude Code finds that folder with CLAUDE_CONFIG_DIR even when it is set
    to an empty string (unlike .claude.json above, where empty means HOME)."""
    ccd = os.environ.get("CLAUDE_CONFIG_DIR")
    legacy = os.path.join(ccd if ccd is not None else os.path.join(HOME, ".claude"), ".config.json")
    try:
        if os.path.isfile(legacy) and os.path.getsize(legacy) > 0:
            return legacy
    except OSError:
        pass
    return CLAUDE_JSON


def claude_mcp_state(name: str) -> str:
    """One word for a server in Claude Code's user list. Prints no values."""
    try:
        # utf-8-sig: Claude Code reads a file that starts with a BOM.
        with open(claude_json(), encoding="utf-8-sig") as fh:
            data = json.load(fh)
    except FileNotFoundError:
        return "gone"
    except (OSError, ValueError):
        return "unknown"
    servers = data.get("mcpServers") if isinstance(data, dict) else None
    if servers is None:
        return "gone" if isinstance(data, dict) else "unknown"
    if not isinstance(servers, dict):
        return "unknown"
    if name not in servers:
        return "gone"
    if name == OLD_ATLASSIAN_NAME and servers[name] == OLD_ATLASSIAN:
        return "kit"
    return "yours"


def main() -> int:
    if sys.argv[1:2] == ["claude-mcp"] and len(sys.argv) == 3:
        print(claude_mcp_state(sys.argv[2]))
        return 0
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("action", choices=["merge", "remove"])
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--tools", default="claude,cursor,gemini")
    p.add_argument("--no-mcp", dest="mcp", action="store_false")
    args = p.parse_args()
    return do_merge(args) if args.action == "merge" else do_remove(args)


if __name__ == "__main__":
    sys.exit(main())
