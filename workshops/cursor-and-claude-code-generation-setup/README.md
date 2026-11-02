# How to set up Cursor and Claude for better code generation

Set up one personal folder, `~/.agents/`, that Cursor, Claude Code and Gemini
CLI all read, so the three tools follow the same preferences. The repo you
work in still wins over these personal files.

- **Audience:** engineers who use Cursor, Claude Code or Gemini CLI locally
- **Duration:** 30 minutes
- **Prerequisites:** macOS or Linux with `bash` and `python3` 3.8+, and at
  least one of Cursor, Claude Code or Gemini CLI. Optional: Atlassian's CLI
  `acli` for Jira (the kit uses it instead of an Atlassian MCP server)
- **What participants leave with:** the personal agent kit installed with one
  command, and a way to undo it

## Contents of this folder

| Path | Contents |
|------|----------|
| [lab/](lab/) | What participants download: the kit folder and its zip |
| [lab/personal-agent-kit/README.md](lab/personal-agent-kit/README.md) | Install, what it changes, undo |
| [lab/personal-agent-kit/companion/](lab/personal-agent-kit/companion/) | Cheat sheets, rules bridge notes and the session memory walkthrough |

## Getting started

Download [personal-agent-kit-v2.zip](lab/personal-agent-kit-v2.zip), unzip it
into `~/src`, then run:

```bash
mkdir -p ~/src && unzip ~/Downloads/personal-agent-kit-v2.zip -d ~/src
bash ~/src/personal-agent-kit/scripts/install.sh --dry-run   # preview only
bash ~/src/personal-agent-kit/scripts/install.sh
```

Undo with `bash ~/.agents/scripts/uninstall.sh`.
