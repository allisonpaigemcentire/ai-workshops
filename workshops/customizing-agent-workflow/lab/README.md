# Lab — Customizing Your Agent Workflow

Participant-facing starter kit. Copy templates into your home directory, run the
sync script for Claude Code, then verify each product you use.

Facilitator material lives one level up — do not put facilitator notes in this
folder.

## Clone this lab

```bash
git clone https://github.com/allisonpaigemcentire/ai-workshops.git
cd ai-workshops/workshops/customizing-agent-workflow/lab
```

You can also download only this `lab/` folder from the repo if your facilitator
shares a zip.

## Before you start

- Open an application repo you use daily (one that already has `AGENTS.md`).
- Have Cursor, Claude Code, Gemini CLI, and/or Firebender available — you only
  verify the tools you actually use.

## Step 1 — Install personal prefs

**Cursor (canonical source for most people)**

```bash
mkdir -p ~/.cursor/rules
cp templates/personal-workflow.mdc ~/.cursor/rules/personal-workflow.mdc
# Edit: replace boilerplate with your own five to ten lines. Keep the Precedence block.
```

**Gemini CLI / Antigravity**

```bash
mkdir -p ~/.gemini
cp templates/GEMINI.md ~/.gemini/GEMINI.md
# Edit to match your Cursor prefs (same text, not repo engineering rules).
```

**Firebender**

```bash
mkdir -p ~/.firebender/rules
cp templates/personal-workflow.mdc ~/.firebender/rules/personal-workflow.mdc
# Or symlink from Cursor:
# ln -sfn ~/.cursor/rules/personal-workflow.mdc ~/.firebender/rules/personal-workflow.mdc
```

Project `.cursor/rules/` in an app repo is **not** `~/.cursor/rules/`. Personal
Cursor rules reach Firebender only through `~/.firebender/rules/`.

## Step 2 — Mirror Cursor rules into Claude Code

From this `lab/` directory:

```bash
bash sync-personal-rules.sh
bash sync-personal-rules.sh --check
```

Expect: `Personal rules bridge: ok (N Cursor rule(s))`.

Optional: copy `templates/claude-exclude.example` to
`~/.cursor/rules/.claude-exclude` if you have situational Cursor-only rules.

Re-run sync after you **add, rename, or remove** a file in `~/.cursor/rules/`.
You do not need to re-run after editing the body of an existing `.mdc`.

## Step 3 — Verify each product (same three steps)

### Claude Code

1. File on disk: sync `--check` passes (above).
2. Product lists files: new session; `/memory` or `/context` shows mirrored rules.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

### Gemini CLI

1. File on disk: `~/.gemini/GEMINI.md` exists with Precedence line.
2. Product lists files: `/memory refresh`, then `/memory show` — confirm
   `GEMINI.md` and repo `AGENTS.md` appear.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

Android Studio Gemini is **not** Gemini CLI. Do not use `/memory show` for Studio.

### Firebender

1. File on disk: `ls -l ~/.firebender/rules/*.mdc` — real file or symlink.
2. Product lists files: new Firebender chat — ask it to name files under
   `~/.firebender/rules` and quote your Precedence line.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

### Cursor

1. File on disk: `ls ~/.cursor/rules/*.mdc`.
2. Product lists files: new Agent chat — distinctive line appears or agent can
   quote your rule.
3. Smoke test: see [verify-checklist.md](verify-checklist.md).

## Step 4 — Exit checklist

Fill in [verify-checklist.md](verify-checklist.md). Keep a copy for yourself.

## Reference

- [Handout](../handout.md) — full guide (precedence, Cloud Agents, skills)
- [Slides](../customizing-your-agent-workflow-slides.html) — open in a browser
- [PR author packet](../pr-author-packet-rule.md) — Goal / Ran / Doubt example

## Script source

`sync-personal-rules.sh` in this folder mirrors `~/.cursor/rules/*.mdc` into
`~/.claude/rules/` as symlinks and manages a personal `~/.claude/CLAUDE.md`
index when appropriate. It does **not** sync Gemini or Firebender — copy prefs
to those paths manually (step 1).
