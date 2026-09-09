# Example personal setup

A finished personal setup that matches the practices in this workshop.
It is a **sample**, not something to drop into an application repo.

Map on your machine:

| In this folder | On your laptop |
|----------------|----------------|
| `home-agents/` | `~/.agents/` |
| `home-agents/instructions/shared.md` | `~/.agents/instructions/shared.md` |
| `wrappers/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `wrappers/cursor/personal-instructions.mdc` | `~/.cursor/rules/personal-instructions.mdc` |
| `wrappers/gemini/GEMINI.md` | `~/.gemini/GEMINI.md` |
| `wrappers/firebender/personal-instructions.mdc` | `~/.firebender/rules/personal-instructions.mdc` |

Prefer **copying `home-agents/` and running the wire script** over copying
`wrappers/` by hand. The script is `lab/wire-personal-agents.sh`. Wrappers
here are so you can see the shape without running it.

## Practices this example follows

1. **Repo files win.** `shared.md` starts with the Precedence block.
2. **Hooks stop; markdown advises.** Confirm-before-push yields to a repo hook.
3. **One personal file.** Edit `shared.md` only.
4. **Git the home folder.** `.gitignore` is present. Reinstall notes are in
   `home-agents/README.md`. Private remote only; no secrets.
5. **Point tools; do not copy prefs by hand.** Wrappers `@`-import or embed
   `shared.md`.
6. **Cloud does not see the laptop.** Nothing in this folder is a Cloud setup.
   Do not symlink `~/.agents` into a repo.
7. **Put writing, tools, and cost in `shared.md`.** Do not put how to build
   this repo, a second copy of a repo skill, a global `--no-verify` rule, or
   tokens.
8. **Three writing lines.** No preamble. No trailing summary of the diff.
   State each finding once.
9. **Main thread plans.** Do not explore in the main loop. Spike unknowns in
   a subagent or a second session.
10. **Same three checks.** See `verify.md`.

## What this example does not include

- Personal skills under `~/.agents/skills/`
- A Claude subagent roster under `~/.agents/agents/`
- Extra Cursor-only `.mdc` files (`lab/sync-personal-rules.sh` is optional)

Those stay in the handout for after class.

## Copy onto your machine (Lab A shape)

From this `example/` directory, after you have cloned the workshop:

```bash
mkdir -p ~/.agents/instructions
cp home-agents/instructions/shared.md ~/.agents/instructions/shared.md
cp home-agents/.gitignore ~/.agents/.gitignore
cp home-agents/README.md ~/.agents/README.md
git -C ~/.agents init
```

Then from `../lab/`:

```bash
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

Adapt the lines in `shared.md`. Keep the Precedence block. Skip any product
you do not use (`--tools=claude,cursor`).
