# Lab — Customizing Your Agent Workflow

Participant-facing starter kit. Write prefs once in `~/.agents/`, point each
product at that file, then verify the products you use.

**Step-by-step walkthrough:** [lab-walkthrough.md](lab-walkthrough.md) (Labs A,
B, C, and exit checks with time boxes).

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
mkdir -p ~/.agents/instructions
cp templates/shared.md ~/.agents/instructions/shared.md
cp templates/agents.gitignore ~/.agents/.gitignore
git -C ~/.agents init
# Edit shared.md. Keep Precedence. Keep the three writing lines.
# Private remote only. Never commit secrets.
```

This is the only file you edit for cross-tool personal prefs. It is **not** a
replacement for repo `AGENTS.md` or repo `.agents/skills/`.

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
| Cursor | `~/.cursor/rules/personal-instructions.mdc` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` (pointer + embedded copy) |
| Firebender | `~/.firebender/rules/personal-instructions.mdc` |

Claude and Cursor wrappers stay live when you edit `shared.md`. **Gemini and
Firebender embed a copy** — re-run the wire script after you edit `shared.md`
if you use those products.

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

1. File on disk: `ls ~/.cursor/rules/personal-instructions.mdc`.
2. Product lists files: new Agent chat — quote the Precedence line.
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
- [Example setup](../example/) — sample `~/.agents/` plus product wrappers
- [Slides (Draft 2)](../customizing-your-agent-workflow-slides-draft-2.html) — 26 slides; practices, labs, then best-practice sources
- [PR author packet](../pr-author-packet-rule.md) — Goal / Ran / Doubt example

## Script source

`wire-personal-agents.sh` in this folder writes thin wrappers so Claude, Cursor,
Gemini, and Firebender all follow `~/.agents/instructions/shared.md`. It does
**not** replace repo `AGENTS.md`, repo skills, or repo hooks.
