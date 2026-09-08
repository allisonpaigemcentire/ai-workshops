#!/usr/bin/env bash
# Mirror personal Cursor user rules into Claude Code's user rules directory.
#
# Canonical: ~/.cursor/rules/*.mdc
# Claude:    ~/.claude/rules/<stem>.md  -> symlink to each .mdc
# Exclude:    ~/.cursor/rules/.claude-exclude (stems to skip)
# Index:     ~/.claude/CLAUDE.md        (only if missing or managed by this script)
#
# Usage:
#   bash scripts/sync-personal-rules.sh          # create/update links
#   bash scripts/sync-personal-rules.sh --check  # report drift; exit 1 if out of sync
#   bash scripts/sync-personal-rules.sh --help

set -euo pipefail

CURSOR_RULES="${CURSOR_RULES:-$HOME/.cursor/rules}"
CLAUDE_RULES="${CLAUDE_RULES:-$HOME/.claude/rules}"
CLAUDE_MD="${CLAUDE_MD:-$HOME/.claude/CLAUDE.md}"
CLAUDE_EXCLUDE="${CLAUDE_EXCLUDE:-$CURSOR_RULES/.claude-exclude}"
MANAGED_MARKER="<!-- managed-by: sync-personal-rules -->"

MODE="sync"
for arg in "$@"; do
  case "$arg" in
    --check) MODE="check" ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done

added=0
removed=0
updated=0
missing=0
conflicts=0
drift_msgs=()

mkdir -p "$CLAUDE_RULES"

# Resolve absolute path for symlink targets (portable; no GNU realpath required).
abs_path() {
  local path="$1"
  local dir base
  dir="$(cd "$(dirname "$path")" && pwd)"
  base="$(basename "$path")"
  printf '%s/%s\n' "$dir" "$base"
}

stem_of_mdc() {
  local base
  base="$(basename "$1")"
  printf '%s\n' "${base%.mdc}"
}

link_path_for_stem() {
  printf '%s/%s.md\n' "$CLAUDE_RULES" "$1"
}

desired_target_for_mdc() {
  abs_path "$1"
}

is_excluded() {
  local stem="$1"
  local line
  [[ -f "$CLAUDE_EXCLUDE" ]] || return 1
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "$line" ]] || continue
    if [[ "$line" == "$stem" ]]; then
      return 0
    fi
  done <"$CLAUDE_EXCLUDE"
  return 1
}

# Phase 1: remove broken symlinks under Claude rules.
shopt -s nullglob
for link in "$CLAUDE_RULES"/*; do
  [[ -L "$link" ]] || continue
  if [[ ! -e "$link" ]]; then
    if [[ "$MODE" == "check" ]]; then
      drift_msgs+=("broken symlink: $link")
      ((missing++)) || true
    else
      rm "$link"
      ((removed++)) || true
    fi
  fi
done

# Phase 1b: remove symlinks for excluded stems.
for link in "$CLAUDE_RULES"/*.md; do
  [[ -L "$link" ]] || continue
  stem="$(basename "$link" .md)"
  if is_excluded "$stem"; then
    if [[ "$MODE" == "check" ]]; then
      drift_msgs+=("excluded stem still linked: $link")
      ((missing++)) || true
    else
      rm "$link"
      ((removed++)) || true
    fi
  fi
done

# Phase 2: ensure each Cursor .mdc has a Claude .md symlink (unless excluded).
declare -a linked_stems=()
for mdc in "$CURSOR_RULES"/*.mdc; do
  [[ -f "$mdc" ]] || continue
  stem="$(stem_of_mdc "$mdc")"
  if is_excluded "$stem"; then
    continue
  fi
  link="$(link_path_for_stem "$stem")"
  target="$(desired_target_for_mdc "$mdc")"
  linked_stems+=("$stem")

  if [[ -e "$link" || -L "$link" ]]; then
    if [[ -L "$link" ]]; then
      current="$(readlink "$link" || true)"
      # Normalize relative readlink results against CLAUDE_RULES.
      if [[ "$current" != /* ]]; then
        current="$(cd "$CLAUDE_RULES" && abs_path "$current")"
      fi
      if [[ "$current" == "$target" ]]; then
        continue
      fi
      if [[ "$MODE" == "check" ]]; then
        drift_msgs+=("wrong target: $link -> $current (want $target)")
        ((missing++)) || true
      else
        ln -sfn "$target" "$link"
        ((updated++)) || true
      fi
    else
      # Real file — never overwrite.
      drift_msgs+=("conflict (not a symlink, left alone): $link")
      ((conflicts++)) || true
    fi
    continue
  fi

  if [[ "$MODE" == "check" ]]; then
    drift_msgs+=("missing link: $link -> $target")
    ((missing++)) || true
  else
    ln -sfn "$target" "$link"
    ((added++)) || true
  fi
done

# Phase 3: managed CLAUDE.md index (sync only; check reports if managed and stale).
should_write_claude_md=0
if [[ ! -f "$CLAUDE_MD" ]]; then
  should_write_claude_md=1
elif grep -qF "$MANAGED_MARKER" "$CLAUDE_MD" 2>/dev/null; then
  should_write_claude_md=1
fi

write_claude_md() {
  local stem link mdc
  {
    printf '%s\n' "$MANAGED_MARKER"
    cat <<'EOF'
# Personal Claude instructions (local only)

These preferences apply across projects on this machine. Canonical copies live
in `~/.cursor/rules/`; this Claude setup mirrors them via symlinks under
`~/.claude/rules/`.

Regenerate this file with `sync-personal-rules.sh` from the workshop lab folder
(or your local copy).

## Precedence

Repo `AGENTS.md`, `.agents/skills/`, repo hooks, and repo rules win over
personal prefs. On conflict, follow the repo. Personal files are how you like
answers, commits, and PRs — not how to build a given tree.

## Mirrored personal rules

Claude loads every file in `~/.claude/rules/` at session start. Edit the Cursor
sources; the Claude links update automatically. After **adding or removing** a
Cursor rule file, re-run the sync script. Stems listed in
`~/.cursor/rules/.claude-exclude` are not mirrored (Claude ignores
`alwaysApply: false`; exclude situational Cursor-only rules there).

| Rule | Source |
|------|--------|
EOF
    for stem in "${linked_stems[@]:-}"; do
      [[ -n "$stem" ]] || continue
      mdc="$CURSOR_RULES/${stem}.mdc"
      printf '| `%s` | `%s` |\n' "$stem" "$mdc"
    done
    cat <<'EOF'

## PR and commit gates (Cursor-only sources)

These stems are in `.claude-exclude` so they do not load every session. When the
task matches, **read the full Cursor source file** before proceeding.

**Pull requests** — read `~/.cursor/rules/creating-pull-requests.mdc` when you
draft, create, or update a PR (including `gh pr create` / `gh pr edit`):

- Use `gh` for GitHub. Open as **draft** unless the user asked for ready in the
  same turn.
- PR body must include **Goal**, **Ran**, and **Doubt** with real content
  (optional Test plan). No placeholder-only sections.
- `r15-services-customer`: validate branch name before branch create, push, or
  PR (no ticket: `am-no-ticket-…` hyphens only; ticketed: `am/<ticket>-…`).
- Do not delegate `gh pr create` or the PR body draft to a subagent.

**Commits** — read `~/.cursor/rules/cody-review-before-commit.mdc` when the user
explicitly asks to **make a commit** (including `--amend`):

- Run PR review on the to-be-committed diff via Task subagents (`sonnet` and
  `opus`) following `~/.claude/skills/cody-pr-review/SKILL.md` before
  `git commit`. Skip only if the user says `skip cody review` or equivalent in
  the same turn.
- Do not use the word "Cody" in anything that gets committed.

## Cross-tool session memory

Personal durable learnings live in `~/.ai-memory/MEMORY.md` (not Claude project
auto-memory under `~/.claude/projects/*/memory/`). At session start, **read**
that file. On wrap-up / corrections, use the `session-memory` skill
(`~/.claude/skills/session-memory` → `~/.cursor/skills/session-memory`).

## Notes

- Cursor frontmatter (`alwaysApply`, `globs`, `description`) is harmless noise
  for Claude; follow the markdown body.
- Repo-shared conventions still come from each project’s `AGENTS.md` /
  `CLAUDE.md` when working in that repo.
- To confirm load: in Claude Code run `/memory` or `/context` and check
  Memory / rules files.
EOF
} >"$CLAUDE_MD"
}

if (( should_write_claude_md )); then
  if [[ "$MODE" == "check" ]]; then
    if [[ ! -f "$CLAUDE_MD" ]]; then
      drift_msgs+=("missing managed index: $CLAUDE_MD")
      ((missing++)) || true
    fi
  else
    write_claude_md
  fi
fi

# Reporting
if [[ "$MODE" == "check" ]]; then
  if (( ${#drift_msgs[@]} > 0 )); then
    echo "Personal rules bridge: out of sync" >&2
    for msg in "${drift_msgs[@]}"; do
      echo "  - $msg" >&2
    done
    exit 1
  fi
  echo "Personal rules bridge: ok (${#linked_stems[@]} Cursor rule(s))"
  exit 0
fi

if (( added > 0 || removed > 0 || updated > 0 || conflicts > 0 )); then
  echo "Personal rules sync: +${added} added, ~${updated} updated, -${removed} removed, !${conflicts} conflicts"
  if (( conflicts > 0 )); then
    for msg in "${drift_msgs[@]}"; do
      echo "  - $msg" >&2
    done
  fi
fi
