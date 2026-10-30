# Personal Cursor ↔ Claude rules bridge

Share personal always-on preferences across coding tools with **one** file
you edit, plus thin wrappers. Not every engineer uses Cursor.

Supported tools: **Cursor, Claude Code and Gemini CLI.**

**Workshop default:** [`scripts/wire-personal-agents.sh`](../scripts/wire-personal-agents.sh).
`scripts/install.sh` runs it for you.

**Optional extra:** [`scripts/sync-personal-rules.sh`](../scripts/sync-personal-rules.sh)
mirrors additional Cursor-only `~/.cursor/rules/*.mdc` files into Claude.

---

## Why this exists

| Location | Who loads it |
|----------|----------------|
| `~/.agents/instructions/shared.md` | Canonical personal prefs — **edit here** |
| `~/.claude/CLAUDE.md` | Claude Code (`@` import of `shared.md`) |
| `~/.cursor/rules/personal-instructions.mdc` | Cursor desktop Agent (wrapper) |
| `~/.gemini/GEMINI.md` | Gemini CLI (managed region with an embedded copy; your other lines are kept) |

Repo conventions (`AGENTS.md`, project `CLAUDE.md`) already work in both tools
when that repo is open. The gap is **personal, machine-local** prefs (writing
style, commit-when-asked, tool habits).

```text
~/.agents/instructions/shared.md
        │
        │  wire-personal-agents.sh
        ▼
~/.claude/CLAUDE.md
~/.cursor/rules/personal-instructions.mdc
~/.gemini/GEMINI.md
```

This is **not** a replacement for repo `.agents/skills/` or `AGENTS.md`.

---

## One-time setup

1. Run the installer once: `bash scripts/install.sh` (see the kit README).
   It creates `~/.agents/instructions/shared.md` from the template.
2. Keep the Precedence block. Write five to ten personal lines in `shared.md`.
3. Re-wire and check:

```bash
bash ~/.agents/scripts/wire-personal-agents.sh
bash ~/.agents/scripts/wire-personal-agents.sh --check
```

4. Start a new session in each product you use. Confirm with `/memory`
   (Claude), `/memory show` (Gemini), or a quote test (Cursor).

---

## After editing `shared.md`

Claude `@` import stays live. **Cursor and Gemini embed a copy**: re-run
the wire script after you edit `shared.md` if you use those products. Those
wrappers are stale until you re-run.

```bash
bash ~/.agents/scripts/wire-personal-agents.sh
bash ~/.agents/scripts/wire-personal-agents.sh --check
```

Gemini CLI also saves your cross-project preferences into
`~/.gemini/GEMINI.md`. The wire script only replaces its own marked region,
so those saved lines survive a re-run. Edits made inside the region are
replaced.

---

## Optional: extra Cursor-only `.mdc` files

If you keep situational Cursor rules under `~/.cursor/rules/*.mdc` that should
**not** live in `shared.md`, `sync-personal-rules.sh` still mirrors those extras
into `~/.claude/rules/` (except stems in `.claude-exclude`). That is not the
workshop default.

---

## Caveats

- **Cursor Cloud Agents** do **not** load `~/.agents/` or `~/.cursor/rules/`
  from your laptop. Copy any personal pref you need in Cloud into the repo or
  team layer.
- **Claude Desktop Projects** (chat-only) do **not** auto-load `~/.claude/rules/`.
- The wire script never overwrites an unmanaged `CLAUDE.md` or `GEMINI.md`.
  On its own it reports a conflict; the installer (or `--adopt`) backs the
  file up and adds one marked region, keeping your lines. An unmanaged
  `personal-instructions.mdc` is always left alone.
- This bridge is **personal only**. Team/shared conventions stay in each repo’s
  `AGENTS.md`.
- Do not commit the contents of your personal prefs unless you intend to share
  them.

---

## Related

- Kit README: [../README.md](../README.md)
- Session memory walkthrough: [personal-session-memory-setup.html](personal-session-memory-setup.html)
