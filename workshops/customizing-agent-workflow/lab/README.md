# Lab — Customizing Your Agent Workflow

Participant-facing starter kit. Write prefs once in `~/.agents/`, point each
product at that file, then verify the products you use.

**Step-by-step walkthrough:** [lab-walkthrough.md](lab-walkthrough.md) (Labs A,
B, C, D, and exit checks with time boxes).

## Clone this lab

```bash
git clone https://github.com/allisonpaigemcentire/ai-workshops.git
cd ai-workshops/workshops/customizing-agent-workflow/lab
```

## Before you start

- Open an application repo you use daily (one that already has `AGENTS.md`).
- Have Cursor, Claude Code, Gemini CLI, and/or Firebender available — you only
  verify the tools you actually use.

## Step 1 — Write the canonical file

```bash
mkdir -p ~/.agents/instructions ~/.agents/rules ~/.cursor/rules
cp templates/shared.md ~/.agents/instructions/shared.md
cp templates/creating-pull-requests.mdc ~/.agents/rules/creating-pull-requests.mdc
ln -sfn ~/.agents/rules/creating-pull-requests.mdc ~/.cursor/rules/creating-pull-requests.mdc
```

Then copy the gitignore and initialize git (**required**):

```bash
cp templates/agents.gitignore ~/.agents/.gitignore
git -C ~/.agents init
```

Edit `shared.md`. Keep Precedence. Keep the three writing lines. Private
remote only. Never commit secrets.

`shared.md` is the only file you edit for cross-tool personal prefs. The
`.mdc` is the Cursor description-match gate for Lab C when the open repo
has no PR headings. Neither file replaces repo `AGENTS.md` or repo
`.agents/skills/`.

## Step 2 — Point each product at that file

From this `lab/` directory:

```bash
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

Expect: `Personal agents wire: ok (N wrapper(s) → …/shared.md)`.

To wire only the products you use:

```bash
bash wire-personal-agents.sh --tools=claude,gemini
bash wire-personal-agents.sh --check --tools=claude,gemini
```

| Product | Wrapper the script writes |
|---------|---------------------------|
| Claude Code | `~/.claude/CLAUDE.md` (`@~/.agents/instructions/shared.md`) |
| Cursor | `~/.cursor/rules/personal-instructions.mdc` (embedded copy) |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` (embedded copy) |
| Firebender | `~/.firebender/rules/personal-instructions.mdc` (embedded copy) |

Claude `@`-imports `shared.md` and stays live when you edit that file.
**Cursor, Gemini, and Firebender embed a copy** — re-run the wire script
after you edit `shared.md` if you use those products. Those wrappers are
stale until you re-run.

Project `.cursor/rules/` in an app repo is **not** the personal wrapper.
Cursor Cloud Agents do **not** load `~/.agents/` or `~/.cursor/rules/` from
your laptop.

## Step 3 — Verify each product (same three steps)

### Claude Code

1. File on disk: wire `--check` passes; `~/.agents/instructions/shared.md` has
   the Precedence block.
2. Product lists files: new session; `/memory` or `/context` shows personal
   `CLAUDE.md` and/or the `@` import.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

### Cursor

1. File on disk: `ls ~/.cursor/rules/personal-instructions.mdc` and
   `ls -l ~/.cursor/rules/creating-pull-requests.mdc`.
2. Product lists files: new Agent chat — quote the Precedence line from
   personal prefs. Do not put the file path in the prompt.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

### Gemini CLI

1. File on disk: `~/.gemini/GEMINI.md` exists with the Precedence line.
2. Product lists files: `/memory refresh`, then `/memory show` — confirm
   `GEMINI.md` and repo `AGENTS.md` appear.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

Android Studio Gemini is **not** Gemini CLI. Do not use `/memory show` for Studio.

### Firebender

1. File on disk: `ls -l ~/.firebender/rules/*.mdc` — wrapper exists.
2. Product lists files: new Firebender chat — ask it to quote the Precedence
   line from your personal prefs.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

## Step 4 — Exit checklist

Fill in [verify-checklist.md](verify-checklist.md). Keep a copy for yourself.

## Optional — extra Cursor-only rules

If you already keep situational files under `~/.cursor/rules/*.mdc` that should
**not** live in `shared.md`, you can still mirror those extras into Claude with
[`sync-personal-rules.sh`](sync-personal-rules.sh). That is not the workshop
default. Workshop default is `shared.md` plus `wire-personal-agents.sh`.

## Reference

- [Handout](../handout.md) — full guide (precedence, Cloud Agents, skills)
- [Example setup](../example/) — sample `~/.agents/` plus product wrappers; [walkthrough](../example/walkthrough.md)
- [Slides](../slides.html) — 19 slides, no speaker notes; practices, Labs A–D, exit, sources
- [Lab D prompt](lab-d-prompt.md) — main-thread / subagent spawn test
- [PR author packet](../pr-author-packet-rule.md) — Goal / Ran / Doubt example

## Script source

`wire-personal-agents.sh` in this folder writes thin wrappers so Claude, Cursor,
Gemini, and Firebender all follow `~/.agents/instructions/shared.md`. It does
**not** replace repo `AGENTS.md`, repo skills, or repo hooks.
