# Examples (optional)

Off by default. To install both, run the installer with `--with-helpers`:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --with-helpers
```

For each tool in `--tools` (default: all three) it puts them where that tool
looks: links in `~/.claude/agents/`, copies in `~/.cursor/agents/` and
`~/.gemini/agents/`. It backs up any file of yours with the same name first,
and `uninstall.sh` puts it back. Or copy what you want by hand.

| File | What it is |
|------|------------|
| `agents/code-reader.md` | Read-only subagent: explains one file, module or PR diff, citing `path:line` (Claude Code format) |
| `agents/doc-reader.md` | Read-only subagent: answers one question from a long doc or web page, citing the source (Claude Code format) |
| `agents/cursor/*.md` | The same two for Cursor: `model: inherit`, `readonly: true` |
| `agents/gemini/*.md` | The same two for Gemini CLI: `kind: local`, `model: inherit`, and a `tools` list of read-only tools only |

The prompt body is the same in all three formats; only the frontmatter
differs. If you edit one, edit the others to match.

How to use them in Claude Code, Cursor and Gemini CLI, and why they help:
[`../docs/borrowed-practices.md`](../docs/borrowed-practices.md#2-read-only-helpers-that-cite-file-and-line).

Adapted from a community kit of local agent optimizations.
