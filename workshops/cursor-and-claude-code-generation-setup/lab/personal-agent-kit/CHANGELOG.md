# Changelog

## v2 (2026-10-30, updated 2026-11-02)

- Jira and Confluence: the installer no longer adds the Atlassian MCP server.
  Agents use Atlassian's CLI, `acli`; `shared.md` tells them to ask you to run
  `acli jira auth login --web` when the sign-in is missing or expired, and
  never to run it or handle a token themselves. The installer checks that
  `acli` is on your PATH and prints the Homebrew install line if not (or,
  when `acli` is installed in a Homebrew folder that is not on your PATH, the
  line that adds that folder). A
  re-run removes the `atlassian` MCP server an earlier kit version added
  (Cursor, Claude Code, Gemini) when it is still the kit's value; so does
  `uninstall.sh`, which keeps one you changed. Claude Code's list is read
  from `CLAUDE_CONFIG_DIR` when that is set (and from its legacy
  `.config.json` when Claude Code uses that), and an unreadable file keeps
  the record so a later run can finish.

- One command: `scripts/install.sh` now previews, asks once, installs, and
  merges the Cursor hooks, Claude settings and MCP config that used to be
  three manual steps. `--dry-run`, `--yes`, `--tools=`, `--no-mcp`.
- Every changed file is backed up to `~/.agent-kit-backups/<time>/` first.
  Merges add only missing entries and never print config values.
- New `scripts/uninstall.sh` removes only what the installer recorded.
- Gemini CLI: the installer adds the optional `team-skills` MCP server to
  `~/.gemini/settings.json`.
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
  subagents into `~/.claude/agents/` (Cursor and Gemini copies: see below).
  A file of yours with the same name is backed up first; `uninstall.sh`
  removes only what it added and restores your file.
- Fixed: `--with-helpers` backs up a link of yours as a link, so uninstall
  puts back the link itself (macOS `cp` copied the file it pointed to and
  stopped the install on a broken link). If a helper replaced your file on
  more than one run, uninstall restores the newest one. Installed helpers
  stay current on later runs without the flag.
- `--help` in `install.sh` and `uninstall.sh` now prints the whole header
  instead of a fixed line range.
- Credits to the community kit no longer name a person.
- Supported tools: Cursor, Claude Code and Gemini CLI only.
- Cursor's main path is now a User Rule: the installer prints `shared.md`
  between marker lines to paste into Customize > Rules > User Rules, and on
  macOS copies it with `pbcopy` when present (`--no-clipboard` skips that).
  `install.sh --print-user-rule` prints it again. `~/.cursor/rules/` stays
  as the fallback.
- `--with-helpers` now also copies the two helpers into `~/.cursor/agents/`
  (`model: inherit`, `readonly: true`) and `~/.gemini/agents/` (Gemini
  format, read-only tools), for the tools in `--tools`. Claude links now
  need Claude Code in `--tools`. Copies are backed up and restored like the
  links; re-runs and uninstall leave a copy you edited.
- `wire-personal-agents.sh` (and `--check`) warns about `<...>` fill-ins
  still blank in `shared.md`. It is a warning; the exit code is unchanged.
- `instructions/shared.template.md` has an optional 3-line model tier
  summary.
- `docs/borrowed-practices.md`: Cursor caveats on legacy request-based plans
  and on the extra tokens parallel subagents use; Gemini CLI helper notes.
- Review fixes: a helper copy you edited is no longer replaced when you
  re-run with `--with-helpers`; uninstall still puts back your original file
  after you deleted a helper copy and re-ran; the fill-in warning skips
  autolinks, emails, generic types such as `List<String>`, indented or `~~~`
  code fences and more HTML tags.
