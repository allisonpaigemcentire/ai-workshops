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
- Supported tools: Cursor, Claude Code and Gemini CLI only.
