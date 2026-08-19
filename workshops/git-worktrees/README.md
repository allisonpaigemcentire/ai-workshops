# Git Worktrees

Safely work on multiple features and bug fixes in parallel without switching branches or stashing changes. This hands-on workshop teaches Git worktrees — a Git primitive that creates separate checkouts of the same repository while sharing commits and branches.

- **Audience:** engineers using AI coding agents who need to work on multiple branches simultaneously
- **Duration:** hands-on workshop
- **Prerequisites:** Git installed; access to a command line or Claude Code / Cursor; familiarity with basic Git branches
- **What participants leave with:** the ability to create, list, and remove a worktree; understanding of when worktrees are the right tool versus switching branches or using a multi-root workspace

## Contents of this folder

- `agenda.md` — run-of-show for the session
- `cheat-sheet.html` — one-page reference participants can keep
- `sources.html` — links and references
- `worktrees-presentation.html` — interactive presentation (19 slides) with built-in navigation, collapsible Claude Code / Cursor alternatives for every Git command, parallel and sequential workflow patterns, fleet view for multiple concurrent PRs with hands-on challenge, and a participant challenge
- `lab/` — the hands-on starter material participants clone

## Workshop structure

The workshop emphasizes the hands-on lab:
- Understand what worktrees are and the rules that prevent mistakes
- Hands-on lab in pairs (create, inspect, test Git's guardrails, clean up)
- Map worktrees to Claude Code and Cursor; decide when worktrees are the right tool

## Running this workshop

1. Each participant or pair clones the lab starter repository (see `lab/README.md` for the command).
2. Open `worktrees-presentation.html` in a browser and navigate using arrow keys or the controls.
3. Follow the presentation through the concept slides, then walk through the lab steps together.
4. Collapsible sections show Claude Code and Cursor alternatives for each Git command.

## What you'll learn

- How worktrees separate working files and staged changes while keeping Git objects and refs shared
- The three rules that prevent most mistakes (one branch per worktree, list before creating, remove with Git)
- How Claude Code and Cursor handle worktrees via CLI flags and slash commands
- When to choose worktrees over switching branches or multi-root workspaces
