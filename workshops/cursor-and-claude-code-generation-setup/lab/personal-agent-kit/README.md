# Personal agent kit (v2)

For the session *How to set up Cursor and Claude for better code generation*
(Mon Nov 2, 4:30 to 5:00 PM ET).

One folder, `~/.agents/`, holds your personal AI preferences. **Cursor,
Claude Code and Gemini CLI** all read it, so you edit one file instead of
three. The repo you work in always wins over these personal files.

You don't need this kit to start. Repo skills and Cursor Cloud work with no
setup. It's for people who use AI tools locally and want one place for their
own preferences.

**Download:** [personal-agent-kit-v2.zip](https://github.com/allisonpaigemcentire/ai-workshops/raw/main/workshops/cursor-and-claude-code-generation-setup/lab/personal-agent-kit-v2.zip)

## Before you start

- macOS or Linux, with `bash` and `python3` 3.8 or newer. On a new Mac,
  run `xcode-select --install` first if `python3` asks to install tools.
- At least one of: Cursor, Claude Code (`claude` on your PATH), Gemini CLI.
- Optional: `jq` for the Claude status line (`brew install jq`).
- Optional: a team skills MCP server. The installer adds it as `team-skills`
  only when you set `KIT_SKILLS_FROM` (the `uvx --from` source, pinned to a
  tag or `main`) and `KIT_SKILLS_ENTRY` (its command name) before you run it,
  and `uv` is installed (`brew install uv`). Your team shares the values.

## Install: one command

Unzip into `~/src`, then run:

```bash
mkdir -p ~/src && unzip ~/Downloads/personal-agent-kit-v2.zip -d ~/src
bash ~/src/personal-agent-kit/scripts/install.sh
```

It prints a full preview, asks once, then installs. To see the preview
without changing anything:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --dry-run
```

Other options: `--yes` (no prompt), `--tools=cursor,claude` (only some
tools), `--no-mcp` (skip MCP servers), `--with-helpers` (also link the
optional read-only `code-reader` and `doc-reader` subagents; off by default).

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
| `~/.cursor/mcp.json` | Adds `atlassian` (OAuth, no token), plus `team-skills` if you set it up (see above). |
| `~/.claude/CLAUDE.md` | Adds one marked section that imports `shared.md`. Your lines stay. |
| `~/.claude/rules/`, `~/.claude/hooks/` | Links to the kit's rules and hooks. Your Cursor rules are mirrored here too. |
| `~/.claude/settings.json` | Adds the stop hook, and the status line if you don't have one. |
| Claude Code user MCP list | Adds the same servers with `claude mcp add`, if `claude` is installed. |
| `~/.gemini/GEMINI.md` | Adds one marked section with a copy of `shared.md`. Your lines and Gemini's saved memories stay. |
| `~/.gemini/settings.json` | Adds the same MCP servers. |
| `~/.claude/agents/` | Only with `--with-helpers`: links `code-reader.md` and `doc-reader.md`. Cursor reads this folder too. A file of yours with the same name is backed up, then replaced. |

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

Cursor finds `~/.cursor/rules/` by walking up from the folder you open, so
these rules load only for projects inside your home folder (for example
`~/src/...`). For a project elsewhere, paste the rule text into Cursor's
Customize → Rules → User Rules instead.

Session memory: the installer links the `session-memory` rule and stop hook,
but not the `~/.ai-memory/` store or the `session-memory` skill. To use it,
follow steps 1 and 2 of `companion/personal-session-memory-setup.html`; skip
its later steps, which the installer already did.

## Undo

```bash
bash ~/.agents/scripts/uninstall.sh --dry-run   # see what it would undo
bash ~/.agents/scripts/uninstall.sh
```

This removes only what the installer recorded: its links, its marked
sections, its wrapper and its config entries. If `--with-helpers` replaced a
file of yours in `~/.claude/agents/`, uninstall puts it back. Files are backed up first. It
leaves `~/.agents/` and your backups, so delete those yourself if you want
(`rm -rf ~/.agents ~/.agent-kit-backups`). To restore a file exactly as it
was, copy it back from `~/.agent-kit-backups/<time>/`.

## Merge by hand

If the installer reports a file as SKIPPED, add these entries yourself.
The examples are in `hooks.example.json` (Cursor hooks),
`claude-settings.example.json` (Claude settings) and `mcp.example.json`
(MCP servers). For Gemini, put the `atlassian` (and optional `team-skills`) entries
under `mcpServers` in `~/.gemini/settings.json`.

## More

- [docs/reference.md](docs/reference.md): what each file does, precedence
  and secrets rules
- [docs/enable-lsp.md](docs/enable-lsp.md): turn on code intelligence
- [docs/borrowed-practices.md](docs/borrowed-practices.md): model tiers,
  read-only helpers that cite file and line, a self-audit prompt and
  permission lessons
- [examples/](examples/): optional read-only subagents (installed only
  with `--with-helpers`)
- [companion/](companion/): rules bridge notes, session memory walkthrough
  and the cheat sheets
