---
name: create-worktree
description: >
  Create an isolated git worktree and branch per ticket so several tickets can
  be worked in parallel without checking out in the primary tree. Use when the
  user wants to start work on a ticket, spin up worktrees, work on several
  tickets at once, or invokes /create-worktree.
---

# Create Worktree

A **personal** skill: your laptop layout for parallel tickets. It is not a
repo skill. Do not copy this into an application repo's `.agents/skills/`.

## Overview

For each ticket, run the bundled script. It creates a git worktree on a new
branch `wt/<TICKET>` (or `wt/<TICKET>-<slug>`) from the repo's default branch.

Worktrees land **outside** the repo:

```
~/Documents/GitHub/.worktrees/<repo>/<TICKET>/
```

Override the parent dir with `WORKTREES_ROOT` if your clones do not live under
`~/Documents/GitHub`.

## Instructions

1. **Collect tickets** from the user's message (for example `TYP-1, TYP-2`).
   Target repo is the one containing the current directory, unless the user
   names another path — then pass `--repo`.
2. **Run the bundled script.** Do not reimplement `git worktree` by hand.

   ```bash
   bash ~/.agents/skills/create-worktree/scripts/create_worktree.sh \
     [--repo PATH] [--base BRANCH] [--dry-run] TICKET[:slug] [TICKET[:slug] ...]
   ```

   Use `--dry-run` first if the user wants a preview.
3. **Relay the summary table** (TICKET / BRANCH / STATUS / PATH). `STATUS` is
   `CREATED`, `EXISTS` (already there), or `ERROR`.
4. Tell the user to **open each new path in its own editor window**. Never
   `git checkout` another ticket's branch in the primary working tree.

## Notes

- Idempotent: a ticket whose branch or worktree already exists reports `EXISTS`.
- A fresh worktree shares git history, not build caches. That is expected.
- When the ticket is done:

  ```bash
  git -C <repo> worktree remove <path>
  git -C <repo> worktree prune
  ```

## Files

```
create-worktree/
├── SKILL.md
├── README.md
└── scripts/
    └── create_worktree.sh
```
