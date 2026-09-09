# create-worktree (sample personal skill)

Create an isolated git worktree and branch per ticket so you can work several
tickets in parallel without disturbing the primary checkout.

This is a **personal** skill (`~/.agents/skills/`). Repo jobs such as
`create-pr` stay in the application repo's `.agents/skills/`.

## Where worktrees live

```
~/Documents/GitHub/.worktrees/<repo>/<TICKET>/
```

Branch name: `wt/<TICKET>` (or `wt/<TICKET>-<slug>`). Change the prefix in
`scripts/create_worktree.sh` if you want your own initials. Override the
parent dir with `WORKTREES_ROOT`.

## Usage

From inside the target repo (or pass `--repo`):

```bash
bash ~/.agents/skills/create-worktree/scripts/create_worktree.sh TYP-1234

bash ~/.agents/skills/create-worktree/scripts/create_worktree.sh --dry-run TYP-1234 TYP-1250
```

The agent should run that script rather than inventing `git worktree` steps.

## Discoverability

After you copy this folder to `~/.agents/skills/create-worktree/`, symlink if
the product does not scan `~/.agents/skills/` itself:

```bash
ln -sfn ~/.agents/skills/create-worktree ~/.cursor/skills/create-worktree
ln -sfn ~/.agents/skills/create-worktree ~/.claude/skills/create-worktree
```
