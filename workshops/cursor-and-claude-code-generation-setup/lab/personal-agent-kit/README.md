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
- Optional: Atlassian's command-line tool `acli`, for Jira (see
  [Jira and Confluence](#jira-and-confluence-acli-not-mcp) below).

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
tools), `--no-mcp` (skip the optional `team-skills` MCP server), `--with-helpers` (also install the
optional read-only `code-reader` and `doc-reader` subagents for each selected
tool; off by default), `--no-clipboard` (see below).

Then fill in the `<placeholders>` in `~/.agents/instructions/shared.md` and
run the same install command again. Start a new chat in each tool.
`wire-personal-agents.sh --check` warns about any `<...>` you left blank; it
is a warning, not a failure.

### Cursor: paste one User Rule (main path)

At the end, the installer prints your `shared.md` between two marker lines.
In Cursor, open **Customize > Rules > User Rules** (older Cursor versions:
**Cursor Settings > Rules > User Rules**), paste that text, and save. User
Rules apply to every project you open, wherever it is on disk. On macOS the
installer also copies the text to your clipboard with `pbcopy` (skip that with
`--no-clipboard`).

After you edit `shared.md`, print it again and paste it over the old rule:

```bash
bash ~/.agents/scripts/install.sh --print-user-rule
```

Fallback: the installer still writes `~/.cursor/rules/personal-instructions.mdc`
and links the kit's rules into `~/.cursor/rules/`. Cursor finds that folder
by walking up from the folder you open, so it loads only for projects inside
your home folder (for example `~/src/...`). If you use the User Rule and the
fallback file, a project under your home folder gets the text twice; that
costs context but does not conflict.

Optional: copy `~/.agents/rules/repo-shorthand.template.mdc` to
`~/.agents/rules/repo-shorthand.mdc`, fill it in, and run the install command
again to link it.

## What it changes

| Where | Change |
|-------|--------|
| `~/.agents/` | New folder with the kit. Your `shared.md` and rules are never overwritten on a re-run. |
| Cursor User Rules | Nothing: you paste the text the installer prints (see above). |
| `~/.cursor/rules/`, `~/.cursor/hooks/` | Links to the kit's rules and hooks, plus the fallback `personal-instructions.mdc`. |
| `~/.cursor/hooks.json` | Adds the session-memory stop hook and the optional cost guard. |
| `~/.cursor/mcp.json` | Adds `team-skills` only if you set it up (see above). Removes the `atlassian` server an earlier kit version added, unless you changed it. |
| `~/.claude/CLAUDE.md` | Adds one marked section that imports `shared.md`. Your lines stay. |
| `~/.claude/rules/`, `~/.claude/hooks/` | Links to the kit's rules and hooks. Your Cursor rules are mirrored here too. |
| `~/.claude/settings.json` | Adds the stop hook, and the status line if you don't have one. |
| Claude Code user MCP list | Same as `~/.cursor/mcp.json`, with `claude mcp add` / `claude mcp remove`, if `claude` is installed. |
| `~/.gemini/GEMINI.md` | Adds one marked section with a copy of `shared.md`. Your lines and Gemini's saved memories stay. |
| `~/.gemini/settings.json` | Same as `~/.cursor/mcp.json`. |
| `~/.claude/agents/` | Only with `--with-helpers` and Claude Code selected: links `code-reader.md` and `doc-reader.md`. |
| `~/.cursor/agents/` | Only with `--with-helpers` and Cursor selected: copies of both in Cursor's format (`model: inherit`, `readonly: true`). |
| `~/.gemini/agents/` | Only with `--with-helpers` and Gemini selected: copies of both in Gemini CLI's format, limited to read-only tools. |

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

For each helper path above, a file or link of yours with the same name is
backed up first, then replaced; uninstall puts it back. A Cursor or Gemini
helper copy you edit later is yours: re-runs and uninstall leave it alone.
The Claude Code helpers are links into `~/.agents/examples/agents/`, and
every run refreshes those files (your edit is backed up to
`~/.agent-kit-backups/<time>/` first). To keep your own Claude version, save
it under a new file name and `name:`, for example `my-code-reader.md`.

In Gemini CLI, trust your project folder (Gemini asks on first run), or
Gemini keeps every MCP server off. Gemini CLI also reads personal skills from
`~/.agents/skills/` itself, so the kit does not link them for Gemini
([Gemini CLI skills docs](https://geminicli.com/docs/cli/skills/)).

Session memory: the installer links the `session-memory` rule and stop hook,
but not the `~/.ai-memory/` store or the `session-memory` skill. To use it,
follow steps 1 and 2 of `companion/personal-session-memory-setup.html`; skip
its later steps, which the installer already did.

## Jira and Confluence: acli, not MCP

The kit adds no Atlassian MCP server. Agents use Atlassian's command-line
tool, `acli`, instead. A CLI adds nothing to the always-on context, while an
MCP server loads its tool descriptions into every chat.

1. Install it (the installer only checks for it and prints this if it is
   missing): on macOS, `brew tap atlassian/homebrew-acli && brew install acli`.
   Other systems: [Atlassian's install guide](https://developer.atlassian.com/cloud/acli/guides/install-acli/).
   If `acli` is in a Homebrew folder (`/opt/homebrew/bin` or `/usr/local/bin`)
   that is not on your PATH, the installer prints the line that adds it.
2. Sign in once, in your own terminal: `acli jira auth login --web`. It opens
   your browser; accept, then pick the same site in the terminal. Check with
   `acli jira auth status`.
3. When the sign-in is missing or expired, the agent stops and asks you to run
   `acli jira auth login --web` again, then retries. The rule is in
   `shared.md` under Tooling. The agent never runs the login for you and
   never asks for an API token, and the kit stores no credential.

Confluence: Atlassian's [acli command reference](https://developer.atlassian.com/cloud/acli/reference/commands/)
documents Jira and organization-admin commands, not Confluence.
For a Confluence page, paste its text or link into the chat.

Upgrading from an earlier kit: re-running the installer removes the
`atlassian` MCP server that version added to Cursor, Claude Code and Gemini,
only where it is still the kit's value. One you changed is kept and named.
Your existing `shared.md` is never overwritten, so copy the two Jira lines
under `## Tooling` in `instructions/shared.template.md` into it (the installer
reminds you), then re-run the installer and paste the Cursor User Rule again.

## Undo

```bash
bash ~/.agents/scripts/uninstall.sh --dry-run   # see what it would undo
bash ~/.agents/scripts/uninstall.sh
```

This removes only what the installer recorded: its links, its marked
sections, its wrapper and its config entries. If `--with-helpers` replaced a
file of yours in `~/.claude/agents/`, `~/.cursor/agents/` or
`~/.gemini/agents/`, uninstall puts it back; a helper copy you edited is left
in place, and so is an `atlassian` MCP server from an earlier kit that you
changed. It cannot see Cursor's User Rules, so delete the pasted rule there
yourself. Files are backed up first. It
leaves `~/.agents/` and your backups, so delete those yourself if you want
(`rm -rf ~/.agents ~/.agent-kit-backups`). To restore a file exactly as it
was, copy it back from `~/.agent-kit-backups/<time>/`.

## Merge by hand

If the installer reports a file as SKIPPED, add these entries yourself.
The examples are in `hooks.example.json` (Cursor hooks),
`claude-settings.example.json` (Claude settings) and `mcp.example.json`
(MCP servers). For Gemini, put the optional `team-skills` entry under `mcpServers` in
`~/.gemini/settings.json`.

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
