# Changelog

## v2 (2026-10-30)

- One command: `scripts/install.sh` now previews, asks once, installs, and
  merges the Cursor hooks, Claude settings and MCP config that used to be
  three manual steps. `--dry-run`, `--yes`, `--tools=`, `--no-mcp`.
- Every changed file is backed up to `~/.agent-kit-backups/<time>/` first.
  Merges add only missing entries and never print config values.
- New `scripts/uninstall.sh` removes only what the installer recorded.
- Gemini CLI: the installer adds MCP servers to `~/.gemini/settings.json`.
  The wire script now replaces only its marked region in `GEMINI.md`, so
  Gemini's saved memories survive a re-run. v1 rewrote the whole file.
- Fixed: re-wiring `CLAUDE.md` added a blank line on every run.
- Fixed: the installer replaced any existing link with its own. It now leaves
  links that point elsewhere alone.
- Fixed: `sync-personal-rules.sh` deleted any broken link in
  `~/.claude/rules/`. It now removes only links it made.
- The team skills MCP server is optional: the installer adds it as
  `team-skills` only when `KIT_SKILLS_FROM` and `KIT_SKILLS_ENTRY` are set.
- Config merges write through a symlinked `settings.json` / `hooks.json` /
  `mcp.json` instead of replacing the link.
- `sync-personal-rules.sh` no longer rewrites a `CLAUDE.md` that the wire
  script manages, so the `shared.md` import survives an upgrade from v1.
- Uninstall removes config files the installer created when nothing else is
  in them, keeps its record when a config file was SKIPPED, and no longer
  leaves an extra blank line in `CLAUDE.md` / `GEMINI.md`.
- Uninstall now also removes the Claude rule links the installer made in
  `~/.claude/rules/`.
- `mcp.example.json` uses `${userHome}` instead of `~`, which Cursor does not
  expand.
- The installer prints a note when only one of `KIT_SKILLS_FROM` and
  `KIT_SKILLS_ENTRY` is set, instead of skipping `team-skills` silently.
- `sync-personal-rules.sh --check` no longer creates `~/.claude/rules/`.
- Fixed: `wire-personal-agents.sh --check` reported "Wrapper embed stale"
  forever when `shared.md` had no final newline or ended in blank lines.
- Fixed: re-running `~/.agents/scripts/install.sh` crashed while merging
  hooks, because the example JSON files were never copied to `~/.agents`.
- New `docs/borrowed-practices.md`, adapted from a community kit: a model
  tier table for Cursor, Claude Code and Gemini, read-only helpers, a
  self-audit prompt and permission lessons. Optional example subagents in
  `examples/agents/` (`code-reader`, `doc-reader`).
- New `install.sh --with-helpers` (off by default) links the two example
  subagents into `~/.claude/agents/`, which Cursor also reads. A file of
  yours with the same name is backed up first; `uninstall.sh` removes only
  the links it added and restores your file.
- `--help` in `install.sh` and `uninstall.sh` now prints the whole header
  instead of a fixed line range.
- Credits to the community kit no longer name a person.
- Supported tools: Cursor, Claude Code and Gemini CLI only.
