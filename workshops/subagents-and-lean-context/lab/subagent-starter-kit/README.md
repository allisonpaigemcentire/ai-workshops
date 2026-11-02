# Subagent starter kit

Three read-only subagents for Cursor and Claude Code, a small installer, a check that finds drift and frontmatter problems, and a prompt that audits the agents you already have.

| Agent | What it does |
|---|---|
| `code-reader` | Explains one file, module or PR diff, citing `path:line`. Describes, never judges. |
| `doc-reader` | Reads a long doc, guide or web page and answers one question, citing the source. |
| `context-checker` | Before a PR, checks your change against the repo's `AGENTS.md`, `CLAUDE.md` and skills. Ends with "clear", "check before PR" or "no context found". |

All three are read-only. In Claude Code they get `tools: Read, Grep, Glob`. In Cursor they get `readonly: true`.

## Quick start

```bash
mkdir -p ~/src && unzip ~/Downloads/subagent-starter-kit.zip -d ~/src
bash ~/src/subagent-starter-kit/install.sh --dry-run   # preview, changes nothing
bash ~/src/subagent-starter-kit/install.sh             # asks once, then installs
```

Claude Code: if `~/.claude/agents/` did not exist before, restart Claude Code once. Cursor: if an agent does not show up yet, start a new chat.

## Use them

| Tool | To be sure the agent runs | Or let the main agent decide |
|---|---|---|
| Cursor | `/code-reader explain src/main.ts` | "Use the code-reader subagent to explain src/main.ts" |
| Claude Code | `@agent-code-reader explain src/main.ts`, or type `@` and pick it from the list | same as Cursor |

In Claude Code, subagents are not slash commands. Typing `@agent-` shows file matches as you type, but the mention still resolves when you send it.

## What the installer does

- Copies `agents/claude/*.md` into `~/.claude/agents/` and `agents/cursor/*.md` into `~/.cursor/agents/`. Nothing else on your machine changes.
- Shows the plan for every file and asks once before it writes anything.
- Leaves a same-name file that is yours alone. `--force` replaces it after a backup in `~/.subagent-starter-kit/backups/`, and uninstall puts it back.
- Updates only the kit's own unchanged copies, so running it again is safe. When everything is current it says "Nothing to change."
- Records what it installed in `~/.subagent-starter-kit/installed.tsv` and adds `~/.subagent-starter-kit/uninstall.sh`.

| Option | Effect |
|---|---|
| `--dry-run` | Show the plan and stop |
| `--yes`, `-y` | Do not ask (needed when there is no terminal) |
| `--force` | Replace same-name files that are yours, after a backup |
| `--tools=claude,cursor` | Install for one tool or both (default both) |
| `--check` | Report drift and lint every agent file, change nothing |
| `-h`, `--help` | Show help |

## Check and audit

```bash
bash ~/src/subagent-starter-kit/install.sh --check
```

For each kit agent it prints `ok`, `DRIFT` (missing, or the kit's older copy: run the install again) or `yours` (changed by you, left alone). Then it lints every `*.md` file in `~/.claude/agents/` and `~/.cursor/agents/` and prints `LINT` lines for problems such as a missing name or description, `---` not on line 1, frontmatter that never closes, a tab at the start of a line, or an unquoted value that contains `: `. Claude Code skips an agent file with these problems and says nothing in the chat, so the agent looks like it never fires.

The lint is a quick check, not a full YAML parser. For a full parse in Claude Code v2.1.233 or later:

```bash
claude plugin validate ~/.claude/agents
```

To review the agents themselves (overlap, vague descriptions, stale paths, missing limits, copies that drifted apart, agents you never call), paste `prompts/audit-subagents.md` into either tool. It returns a ranked shortlist and changes nothing until you pick.

## Undo

```bash
bash ~/.subagent-starter-kit/uninstall.sh --dry-run
bash ~/.subagent-starter-kit/uninstall.sh
```

It removes only the files the kit installed and has not seen you change, restores any file that `--force` replaced, and keeps the backups folder.

## Files

```
subagent-starter-kit/
  README.md
  install.sh                 install, --check, --dry-run
  uninstall.sh               copied to ~/.subagent-starter-kit/ on install
  agents/claude/             code-reader.md, doc-reader.md, context-checker.md
  agents/cursor/             the same three, with Cursor fields
  prompts/audit-subagents.md the audit prompt
  companion/subagents-and-lean-context.html   the workshop deck
  companion/lean-context-cheat-sheet.html     one-page cheat sheet (prints on one letter page)
```

Works with Cursor and Claude Code on macOS and Linux with bash 3.2 or later. No other tools are supported by this kit.
