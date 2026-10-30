# Personal agent kit (v2)

For the session *How to set up Cursor and Claude for better code generation*
(Mon Nov 2, 4:30 to 5:00 PM ET).

One folder, `~/.agents/`, holds your personal AI preferences. **Cursor,
Claude Code and Gemini CLI** all read it, so you edit one file instead of
three. The repo you work in always wins over these personal files.

You don't need this kit to start. Repo skills and Cursor Cloud work with no
setup. It's for people who use AI tools locally and want one place for their
own preferences.

**Download:** [personal-agent-kit-v2.zip](https://github.com/allisonpaigemcentire/ai-workshops/tree/main/workshops/cursor-and-claude-code-generation-setup/lab)

## Before you start

- macOS or Linux, with `bash` and `python3` 3.8 or newer. On a new Mac,
  run `xcode-select --install` first if `python3` asks to install tools.
- At least one of: Cursor, Claude Code (`claude` on your PATH), Gemini CLI.
- Optional: `jq` for the Claude status line (`brew install jq`), and `uv`
  (`brew install uv`) for the team skills MCP server. Without `uv`, the
  installer skips that one server and says so.
- Optional: GitHub access to `urbn/r15-tech-skills` for the team skills MCP
  server.

## Install: one command

Unzip into `~/src`, then run:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh
```

It prints a full preview, asks once, then installs. To see the preview
without changing anything:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --dry-run
```

Other options: `--yes` (no prompt), `--tools=cursor,claude` (only some
tools), `--no-mcp` (skip MCP servers).

Then fill in the `<placeholders>` in `~/.agents/instructions/shared.md` and
run the same install command again. Start a new chat in each tool.

Optional: copy `~/.agents/rules/repo-shorthand.template.mdc` to
`~/.agents/rules/repo-shorthand.mdc`, fill it in, and run the install command
again to link it.

## What it changes

| Where | Change |
|-------|--------|
| `~/.agents/` | New folder with the kit. Your `shared.md` and rules are never overwritten on a re-run. |
| `~/.cursor/rules/`, `~/.cursor/hooks/` | Links to the kit's rules and hooks, plus `personal-instructions.mdc`. |
| `~/.cursor/hooks.json` | Adds the session-memory stop hook and the optional cost guard. |
| `~/.cursor/mcp.json` | Adds `atlassian` (OAuth, no token) and `nuuly-skills` (pinned to `main`). |
| `~/.claude/CLAUDE.md` | Adds one marked section that imports `shared.md`. Your lines stay. |
| `~/.claude/rules/`, `~/.claude/hooks/` | Links to the kit's rules and hooks. Your Cursor rules are mirrored here too. |
| `~/.claude/settings.json` | Adds the stop hook, and the status line if you don't have one. |
| Claude Code user MCP list | Adds the same two servers with `claude mcp add`, if `claude` is installed. |
| `~/.gemini/GEMINI.md` | Adds one marked section with a copy of `shared.md`. Your lines and Gemini's saved memories stay. |
| `~/.gemini/settings.json` | Adds the same two MCP servers. |

How it stays safe:

- **Backs up first.** Every file it changes is copied to
  `~/.agent-kit-backups/<time>/` first. That folder is private to you
  (mode 700) and sits outside `~/.agents`.
- **Adds, never replaces.** If you already have a status line, a hook or an
  MCP server with the same name, yours is kept.
- **Safe to re-run.** If nothing changed, a re-run writes nothing.
- **Leaves your files alone.** A real file where the kit wants a link is
  reported and left in place. A config file it can't read as plain JSON,
  such as a Gemini `settings.json` with comments, is skipped and reported.
- **Never prints values from your config files.** It only names the keys it
  adds. It never asks for or stores a token.

In Gemini CLI, trust your project folder (Gemini asks on first run), or
Gemini keeps every MCP server off.

## Undo

```bash
bash ~/.agents/scripts/uninstall.sh --dry-run   # see what it would undo
bash ~/.agents/scripts/uninstall.sh
```

This removes only what the installer recorded: its links, its marked
sections, its wrapper and its config entries. Files are backed up first. It
leaves `~/.agents/` and your backups, so delete those yourself if you want
(`rm -rf ~/.agents ~/.agent-kit-backups`). To restore a file exactly as it
was, copy it back from `~/.agent-kit-backups/<time>/`.

## Merge by hand

If the installer reports a file as SKIPPED, add these entries yourself.
The examples are in `hooks.example.json` (Cursor hooks),
`claude-settings.example.json` (Claude settings) and `mcp.example.json`
(MCP servers). For Gemini, put the `atlassian` and `nuuly-skills` entries
under `mcpServers` in `~/.gemini/settings.json`.

## More

- [docs/reference.md](docs/reference.md): what each file does, precedence
  and secrets rules
- [docs/enable-lsp.md](docs/enable-lsp.md): turn on code intelligence
- [companion/](companion/): rules bridge notes, session memory walkthrough
  and the cheat sheets
