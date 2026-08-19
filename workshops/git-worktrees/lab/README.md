# Git Worktrees Lab

Welcome to the hands-on lab. In this lab, you will create, inspect, and remove a linked worktree using Git commands, then see how Claude Code and Cursor handle the same steps.

## Before you start

Clone the playground repository. The facilitator will provide the URL and the command. It will look like:

```bash
git clone https://github.com/urbn/ai_enablement_workshops.git worktrees-playground
cd worktrees-playground
```

Run a quick check to make sure the playground is clean:

```bash
git status --short
git worktree list
```

Both should print nothing (or just show the main worktree). If they print anything else, ask the facilitator for a fresh clone.

## Lab steps

Follow along with the presentation. Each step has a Git command and a collapsible section showing how to do the same thing in Claude Code or Cursor.

### Step 1: Create a linked worktree

Create a new worktree with a branch named after yourself. Replace `ac` with your initials:

```bash
git worktree add -b workshop/ac ../worktrees-wt-ac HEAD
git worktree list
```

**Checkpoint:** The list shows two paths: the main checkout and your new worktree. The new row points to `workshop/ac`.

### Step 2: Inspect the worktree

Move into the worktree and create a file:

```bash
cd ../worktrees-wt-ac
printf "created in the linked worktree\n" > worktree-lab.txt
git status --short
git branch --show-current
git worktree list
```

**Checkpoint:** The new file exists only in the linked worktree. Ask your partner to check that the main checkout does not contain `worktree-lab.txt`.

### Step 3: Observe Git's guardrail

While `workshop/ac` is checked out in your worktree, try to check out that same branch in a second worktree:

```bash
git worktree add ../worktrees-wt-duplicate workshop/ac
```

**Expected result:** Git reports that the branch is already checked out. This refusal protects both working trees from sharing one branch checkout.

### Step 4: Clean up

Return to the main checkout and remove the worktree:

```bash
cd ../worktrees-playground
git worktree remove ../worktrees-wt-ac
```

The first removal should fail because `worktree-lab.txt` would be lost. Remove the file first:

```bash
rm ../worktrees-wt-ac/worktree-lab.txt
git worktree remove ../worktrees-wt-ac
git branch -d workshop/ac
git worktree list
```

**Done:** Only the main checkout remains. Do not use `--force` unless you have deliberately decided to discard work.

## Reference

- [Cheat sheet](../cheat-sheet.html) — one-page Git worktrees commands and Claude Code / Cursor alternatives
- [Sources](../sources.html) — links to primary documentation and key practices
