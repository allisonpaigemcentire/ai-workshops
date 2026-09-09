# Example folder walkthrough

This folder is a **finished sample** of the personal setup Labs A–D produce.
It is not a team harness. Do not copy it into an application repo.

Hands-on class still uses `lab/templates/` and `lab/wire-personal-agents.sh`.
Use this folder to see the shape, or to copy a complete sample onto a laptop
after class.

**Before you start:** clone the workshop and open this directory:

```bash
git clone https://github.com/allisonpaigemcentire/ai-workshops.git
cd ai-workshops/workshops/customizing-agent-workflow/example
```

---

## What you are looking at

```
example/
├── README.md                 # Map: this folder → paths on your laptop
├── walkthrough.md            # This file
├── home-agents/              # Maps to ~/.agents/
│   ├── README.md
│   ├── .gitignore
│   ├── instructions/
│   │   └── shared.md         # Canonical personal prefs (edit this)
│   ├── rules/
│   │   └── creating-pull-requests.mdc  # Goal / Ran / Doubt (Cursor symlink)
│   └── skills/
│       └── create-worktree/  # Optional sample personal skill
└── wrappers/                 # What the wire script writes (do not copy by hand)
    ├── claude/CLAUDE.md
    ├── cursor/personal-instructions.mdc
    ├── gemini/GEMINI.md
    └── firebender/personal-instructions.mdc
```

| In this folder | On your laptop |
|----------------|----------------|
| `home-agents/` | `~/.agents/` |
| `home-agents/instructions/shared.md` | `~/.agents/instructions/shared.md` |
| `home-agents/rules/creating-pull-requests.mdc` | `~/.agents/rules/creating-pull-requests.mdc` (symlink from `~/.cursor/rules/`) |
| `home-agents/skills/create-worktree/` | `~/.agents/skills/create-worktree/` |
| `wrappers/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `wrappers/cursor/personal-instructions.mdc` | `~/.cursor/rules/personal-instructions.mdc` |
| `wrappers/gemini/GEMINI.md` | `~/.gemini/GEMINI.md` |
| `wrappers/firebender/personal-instructions.mdc` | `~/.firebender/rules/personal-instructions.mdc` |

---

## Step 1 — Read the canonical file

Open `home-agents/instructions/shared.md`.

Confirm:

1. It starts with **Precedence**: repo `AGENTS.md`, skills, hooks, and rules
   win. On conflict, follow the repo.
2. **How I work** has the three writing lines: no preamble, no trailing
   summary of the diff, state each finding once.
3. Confirm-before-push **yields** to a repo hook (markdown advises; hooks stop).
4. **Context cost** says the main thread plans; do not explore in the main loop.
5. **Defaults** do not invent a global always/never `--no-verify`. Branch
   names follow the **open repo**.
6. **PR descriptions** require `## Goal`, `## Ran`, and `## Doubt` unless the
   open repo names different headings (this workshop uses What / Why this repo /
   Verify).

This is the only file you edit for cross-tool personal prefs. Wrappers only
point at it or embed a copy of it.

---

## Step 2 — See the home-folder extras

Open `home-agents/.gitignore`. It blocks `.env`, keys, tokens, and secrets.
`~/.agents/` is a personal git tree. Private remote only. Do not push it
public. Do not commit secrets.

Open `home-agents/README.md`. That is the README you would keep inside
`~/.agents/` after you copy this tree: edit `shared.md`, run the wire script,
re-run after edits if you use Cursor, Gemini, or Firebender.

---

## Step 3 — Compare the four wrappers (do not copy these by hand)

Prefer running `lab/wire-personal-agents.sh` so the script writes these files
on your machine. The copies here are so you can see the shape.

### Claude — live `@` import

Open `wrappers/claude/CLAUDE.md`.

- Managed markers wrap a short region.
- The load line is `@~/.agents/instructions/shared.md`.
- Claude Code expands that import. After you edit `shared.md`, a new Claude
  session sees the new text. You do not re-run the wire script for Claude.

This `@` is **personal**. It is not how frontend or services repos wire
Claude. In an application repo, `CLAUDE.md` is a symlink to `AGENTS.md` (or
`@AGENTS.md` in that same tree). Do not put `@~/.agents` in a repo: Cloud
and teammates only see the clone.

### Cursor — embed

Open `wrappers/cursor/personal-instructions.mdc`.

- Frontmatter: `alwaysApply: true` and `managed-by: wire-personal-agents`.
- After `<!-- canonical-shared.md -->` the **full body** of `shared.md`.
- Cursor loads `~/.cursor/rules/*.mdc`. It does not reliably expand
  `@~/…`. The embed is what the product injects.
- After you edit `shared.md`, re-run the wire script or this file is stale.
  `wire-personal-agents.sh --check` compares the embed to `shared.md`.

### Gemini — embed

Open `wrappers/gemini/GEMINI.md`.

- Same idea: pointer text, then `<!-- canonical-shared.md -->`, then the
  `shared.md` body, then the managed end marker.
- Antigravity uses this same `~/.gemini/GEMINI.md`. Android Studio Gemini
  is a different product; do not use `/memory show` for Studio.
- Re-run the wire script after you edit `shared.md`.

### Firebender — embed

Open `wrappers/firebender/personal-instructions.mdc`.

- Same as Cursor: frontmatter plus embed after `<!-- canonical-shared.md -->`.
- Project `.cursor/rules/` in an app repo is **not** this wrapper.
- Re-run the wire script after you edit `shared.md`.

---

## Step 4 — Optional: the sample personal skill

Open `home-agents/skills/create-worktree/`.

| File | Role |
|------|------|
| `SKILL.md` | Tells the agent when to run and to call the script |
| `scripts/create_worktree.sh` | Does the `git worktree` work |
| `README.md` | How to invoke it and how to symlink discovery dirs |

This is a **personal** skill (`~/.agents/skills/`). It is not a repo skill.
Do not copy it into an application repo's `.agents/skills/`. Repo jobs such
as `create-pr` stay in the clone.

After you copy it to `~/.agents/skills/create-worktree/`, symlink if the
product does not scan `~/.agents/skills/` itself:

```bash
ln -sfn ~/.agents/skills/create-worktree ~/.cursor/skills/create-worktree
ln -sfn ~/.agents/skills/create-worktree ~/.claude/skills/create-worktree
```

This example does **not** include extra Cursor-only `.mdc` files or a Claude
subagent roster. Those are after-class (handout sections 11–12).

---

## Step 5 — Confirm Labs B–D would pass for this sample

This sample is already wired. On your machine, Labs B–D are the real checks.

Load checks (new session, do not paste the file path into the Cursor or
Firebender quote prompt):

- Cursor: quote the Precedence line from personal prefs.
- Claude: `/memory` or `/context` lists personal `CLAUDE.md` or the `@` import.
- Gemini CLI: `/memory refresh` then `/memory show` lists `GEMINI.md` and
  repo `AGENTS.md`.
- Firebender: quote the Precedence line from personal prefs.

Smoke test (same prompt twice; do **not** open or push a PR):

```
Draft a PR body for my current branch. Do not open or push a PR.
```

1. Application repo **without** PR body headings → `## Goal`, `## Ran`, `## Doubt`.
2. Cloned **ai-workshops** → `## What`, `## Why this repo`, `## Verify`.

Pass on (2): the agent uses the workshop headings. Fail: it still uses Goal /
Ran / Doubt in this clone.

Cursor Cloud Agents do not load anything in this folder. Put must-have Cloud
prefs in the repo harness or Team Rules (handout section 7).

---

## Step 6 — Optional: copy this sample onto your laptop

Class Lab A copies `lab/templates/shared.md`, not this example, unless you
choose the finished sample on purpose.

From this `example/` directory:

```bash
mkdir -p ~/.agents/instructions ~/.agents/skills
cp home-agents/instructions/shared.md ~/.agents/instructions/shared.md
cp home-agents/.gitignore ~/.agents/.gitignore
cp home-agents/README.md ~/.agents/README.md
cp -R home-agents/skills/create-worktree ~/.agents/skills/create-worktree
git -C ~/.agents init
```

Then from `../lab/`:

```bash
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

Only the products you use:

```bash
bash wire-personal-agents.sh --tools=claude,cursor
bash wire-personal-agents.sh --check --tools=claude,cursor
```

Adapt `~/.agents/instructions/shared.md`. Keep the Precedence block. Do not
copy `wrappers/` by hand unless you are inspecting them.

If `~/.claude/CLAUDE.md` or `~/.gemini/GEMINI.md` already exists and is not
managed, the script reports a **conflict**. Back up that file, or add the
managed markers, then re-run.

---

## Step 7 — Confirm you did not mix layers

- This tree is **personal**. Repo `AGENTS.md` still wins on conflict.
- Do not symlink `~/.agents` into an application repo.
- Do not re-author a repo skill here under the same name.
- After you edit `shared.md`, re-run the wire script if you use Cursor,
  Gemini, or Firebender. Claude stays live via `@`.

---

## Related

- [README.md](README.md) — map and copy commands
- [../lab/lab-walkthrough.md](../lab/lab-walkthrough.md) — Labs A, B, C, and D
- [../handout.md](../handout.md) — precedence, Cloud, skills
- [../lab/wire-personal-agents.sh](../lab/wire-personal-agents.sh) — writes the wrappers
