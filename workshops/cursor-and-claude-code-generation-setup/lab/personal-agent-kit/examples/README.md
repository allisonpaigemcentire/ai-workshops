# Examples (optional)

Off by default. To install both, run the installer with `--with-helpers`:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --with-helpers
```

It links them into `~/.claude/agents/` (Cursor reads that folder too), backs
up any file of yours with the same name first, and `uninstall.sh` puts it
back. Or copy what you want by hand.

| File | What it is |
|------|------------|
| `agents/code-reader.md` | Read-only subagent: explains one file, module or PR diff, citing `path:line` |
| `agents/doc-reader.md` | Read-only subagent: answers one question from a long doc or web page, citing the source |

How to use them in Claude Code and Cursor, and why they help:
[`../docs/borrowed-practices.md`](../docs/borrowed-practices.md#2-read-only-helpers-that-cite-file-and-line).

Adapted from a community kit of local agent optimizations.
