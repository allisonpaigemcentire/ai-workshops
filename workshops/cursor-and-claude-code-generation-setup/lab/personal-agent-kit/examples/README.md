# Examples (optional)

Off by default. To install just these three subagents for Cursor and
Claude Code:

```bash
bash ~/src/personal-agent-kit/agents/install-sample-agents.sh
```

Or install them with the rest of the kit, for each tool in `--tools`
(default: all three):

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --with-helpers
```

Either way it puts them where each tool looks: links in `~/.claude/agents/`,
copies in `~/.cursor/agents/` and `~/.gemini/agents/`. `context-checker` has
no Gemini CLI copy, so Gemini gets only the first two. It backs up any file of yours with the same name first,
and `uninstall.sh` puts it back. Or copy what you want by hand.

| File | What it is |
|------|------------|
| `agents/code-reader.md` | Read-only subagent: explains one file, module or PR diff, citing `path:line` (Claude Code format) |
| `agents/doc-reader.md` | Read-only subagent: answers one question from a long doc or web page, citing the source (Claude Code format) |
| `agents/context-checker.md` | Read-only subagent: checks a change against the repo's `AGENTS.md`, `CLAUDE.md` and skills before a PR (Claude Code format) |
| `agents/cursor/*.md` | The same three for Cursor: `model: inherit`, `readonly: true` |
| `agents/gemini/*.md` | `code-reader` and `doc-reader` for Gemini CLI: `kind: local`, `model: inherit`, and a `tools` list of read-only tools only |

The prompt body is the same in every format; only the frontmatter
differs. If you edit one, edit the others to match.

How to use them in Claude Code, Cursor and Gemini CLI, and why they help:
[`../docs/borrowed-practices.md`](../docs/borrowed-practices.md#2-read-only-helpers-that-cite-file-and-line).
