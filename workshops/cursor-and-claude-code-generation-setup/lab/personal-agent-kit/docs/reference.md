# Personal agent kit: reference

Supports **Cursor, Claude Code and Gemini CLI** only.

**You don't need this kit to start.** Repo skills and Cursor Cloud work with
no setup. This kit is optional, for people who use more than one AI tool
locally and want one place for their personal preferences.

One folder, `~/.agents/`, holds your personal AI preferences. Cursor, Claude
Code, and Gemini CLI all read it through links or generated wrappers, so
you edit one file instead of three.

```
~/.agents/
├── instructions/shared.md   # always-on personal prefs (from shared.template.md)
├── rules/*.mdc              # extra rules → ~/.cursor/rules/, mirrored to ~/.claude/rules/
├── hooks/cursor/, claude/   # session-memory stop hook, optional cost guard
├── scripts/                 # install, uninstall, wire, sync, config merge, Keychain wrapper
└── statusline/              # Claude Code status line
```

| Tool | How it reads `~/.agents` |
|------|--------------------------|
| Claude Code | `~/.claude/CLAUDE.md` `@`-imports `shared.md` (live); rules symlinked into `~/.claude/rules/` |
| Cursor | Main path: a User Rule you paste from `install.sh --print-user-rule` (Customize > Rules > User Rules; paste again after edits). Fallback: `~/.cursor/rules/personal-instructions.mdc` embeds a copy (re-run wire after edits), loaded only for projects under your home folder; rules and hooks symlinked |
| Gemini CLI | `~/.gemini/GEMINI.md` holds a marked region with a copy (re-run wire after edits); MCP servers in `~/.gemini/settings.json`; personal skills read from `~/.agents/skills/` directly |

Cursor User Rules are "global preferences defined in Customize → Rules that
apply across all projects" ([Cursor rules docs](https://cursor.com/docs/context/rules)).
Gemini CLI loads user skills from "`~/.gemini/skills/` or the
`~/.agents/skills/` alias" ([Gemini CLI skills docs](https://geminicli.com/docs/cli/skills/)),
so `~/.agents/skills/<name>/` works in Gemini without a link.

## Install

See the [README](../README.md): one command, `bash scripts/install.sh`, with
`--dry-run` to preview. What it changes and how to undo it are listed there.

Check for drift any time:

```bash
bash ~/.agents/scripts/wire-personal-agents.sh --check
bash ~/.agents/scripts/sync-personal-rules.sh --check
```

`wire-personal-agents.sh --check` exits 1 on drift. A `<...>` fill-in still
blank in `shared.md` prints a warning with its line number and does not
change the exit code. It cannot see Cursor's User Rules; paste the text again
after each edit.

Recommended next: turn on code intelligence so the agent navigates by symbol
and sees its own type errors. See [`enable-lsp.md`](enable-lsp.md).

## Precedence: the repo wins

1. What you type in this chat turn.
2. The repo: nearest `AGENTS.md`, `.agents/skills/`, repo hooks and rules.
3. Thin repo adapters (`CLAUDE.md` → `AGENTS.md`, `.gemini/settings.json`).
4. Personal: `~/.agents/instructions/shared.md` and its wrappers.
5. Model defaults.

Personal files say how you like answers, commits, and PRs. They never say how
to build, test, branch, or lint a given repo; the repo owns that.

## What is in the kit

| Piece | Purpose |
|-------|---------|
| `instructions/shared.template.md` | Writing style, status reports, context-cost habits, push/commit defaults |
| `rules/review-context-before-push.mdc` | Refuse `git push` while `REVIEW(context):` annotations remain |
| `rules/git-commit-preexisting-lints-no-verify.mdc` | Commit only when asked; `--no-verify` only for lint failures that predate the diff |
| `rules/session-memory.mdc` | Load `~/.ai-memory/MEMORY.md`; capture corrections at wrap-up |
| `rules/repo-shorthand.template.mdc` | Map "frontend repos" etc. to paths |
| `rules/.claude-exclude` | Rules Claude should not load every session (Claude ignores `alwaysApply: false`) |
| `hooks/*/session-memory-stop.*` | Stop hook: nudges a memory wrap-up after a correction, capped at 2, fails open |
| `hooks/cursor/session-cost-guard.sh` + `session_cost_lib.py` | Optional: one nudge to start a fresh chat past 25 turns or 15M input tokens. Reads the Span hook log; silent without it |
| `statusline/statusline-command.sh` | Claude status line: model, dir, branch, PR, context % |
| `statusline/statusline.py` | Optional richer status line with session cost and monthly usage (see its privacy note) |
| `scripts/mcp-env-from-keychain.sh` | Start an MCP server with tokens read from Keychain at launch |
| `scripts/kit_config.py` | Merges (and on uninstall removes) the kit's hook, status line and MCP entries |
| `scripts/uninstall.sh` | Undoes what the installer recorded |
| `docs/enable-lsp.md` | Turn on LSP code intelligence in Claude Code and Cursor (Python, TS/JS, Swift, Kotlin) |
| `docs/borrowed-practices.md` | Model tiers per tool, lean context, read-only helpers and a self-audit prompt |
| `examples/agents/*.md` | Optional read-only subagents (Claude Code format): `code-reader` and `doc-reader`, which cite file and line, and `context-checker`, which checks a change against the repo's `AGENTS.md`, `CLAUDE.md` and skills; linked into `~/.claude/agents/` only with `install.sh --with-helpers` or `--helpers-only` |
| `examples/agents/cursor/*.md`, `examples/agents/gemini/*.md` | The same subagents in Cursor format (all three) and Gemini CLI format (`code-reader` and `doc-reader` only); copied into `~/.cursor/agents/` and `~/.gemini/agents/` only with those flags |
| `agents/install-sample-agents.sh` | Installs only the three subagents for Cursor and Claude Code (runs `install.sh --helpers-only --tools=claude,cursor`); `--check` reports drift and changes nothing; undo with `uninstall.sh` |

Not included on purpose: personal skills, PR-authoring rules with reviewer
lists, and anything team-wide. Team skills come from the team skills MCP
(`team-skills`, optional) or the repo.

## Secrets: never inline

- No token, password, or API key in `mcp.json`, `settings.json`, `hooks.json`,
  `shared.md`, or anything under `~/.agents/`.
- Prefer OAuth MCP servers (no secret on disk). For Jira, the kit uses
  Atlassian's CLI `acli` and adds no Atlassian MCP server. `acli` keeps its
  own sign-in (`acli jira auth login --web`); the kit stores no credential.
  See the README section "Jira and Confluence: acli, not MCP".
- When a server needs a token, use `${env:VAR}` in `mcp.json` or
  `scripts/mcp-env-from-keychain.sh`.
- Pin the team skills MCP to a tag or `main`, never a feature branch.

## What NOT to put here

- Repo build, test, lint, branch, or codegen rules (they belong in that repo's `AGENTS.md`).
- A copy of a repo or team skill under the same name.
- Tokens, `.env` files, OAuth credential files.
- `~/.ai-memory/` contents, `~/.claude.json`, `~/.gemini/oauth_creds.json`.
- Reviewer lists, personal repo names, or internal documents.

## Do not

- Push `~/.agents` to a public remote, or symlink it into an application repo.
- Expect cloud agents to load these files; they only see the repo.
