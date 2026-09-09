# Personal `~/.agents/` (example)

This folder is what `~/.agents/` looks like after the workshop labs.

**Edit** `instructions/shared.md` only for cross-tool prefs. Point Claude,
Cursor, Gemini, and Firebender at that file with `lab/wire-personal-agents.sh`.
Do not paste the same prefs into each product by hand.

Optional: `skills/create-worktree/` is a sample personal skill (one job, one
script). Copy it to `~/.agents/skills/` and symlink discovery dirs if the
product does not scan that folder. Do not copy it into an application repo.

## Reinstall on a new machine

```bash
# After you clone *your* private copy of this tree to ~/.agents:
mkdir -p ~/.agents/instructions ~/.agents/rules ~/.agents/skills ~/.cursor/rules
# copy instructions/shared.md, rules/creating-pull-requests.mdc, .gitignore,
# and skills/create-worktree here
ln -sfn ~/.agents/rules/creating-pull-requests.mdc ~/.cursor/rules/creating-pull-requests.mdc
git -C ~/.agents init   # if this is a fresh folder
```

Then from the workshop `lab/` folder:

```bash
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

Re-run the wire script after you edit `shared.md` if you use Cursor, Gemini,
or Firebender (those wrappers embed a copy). Claude `@`-imports the file, so
that wrapper stays live.

## Do not

- Commit tokens, `.env`, or keys (see `.gitignore`).
- Push this tree to a public remote.
- Copy or symlink this folder into an application repo.
- Treat this as a replacement for repo `AGENTS.md` or repo `.agents/skills/`.
- Expect Cursor Cloud Agents to load these files. Promote team requirements
  into the repo harness or Team Rules before a Cloud run.
