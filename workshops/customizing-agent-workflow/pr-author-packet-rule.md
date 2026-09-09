# PR author-packet rule — personal setup and Cloud workaround

How to make agents use **Goal / Ran / Doubt** (plus optional **Test plan**) in
every pull request description on your machine, and what to do when the agent
runs in **Cursor Cloud** instead of local desktop chat.

Related: [lab/README.md](lab/README.md).

---

## What the format is

| Section | Required | Content |
|---------|----------|---------|
| **Goal** | Yes | What changed and why, in your words — not the file list |
| **Ran** | Yes | Commands/checks you ran and outcomes — not "CI is green" alone |
| **Doubt** | Yes | Where a miss would hurt; what you still do not know |
| **Test plan** | Optional | Checklist only; does not replace Goal, Ran, Doubt |

Packet idea: [How to Review AI-Generated Pull Requests](https://www.aibuilderclub.com/blog/reviewing-ai-generated-pull-requests).

---

## Local setup (desktop Agent, Claude Code, Gemini CLI)

Personal prefs live in `~/.agents/instructions/shared.md`. Wrappers in each
product's home folder point at that file. They do **not** commit to git.

### 1. Canonical file

Put Goal / Ran / Doubt in `~/.agents/instructions/shared.md` (the workshop
template already does). Copy
[`lab/templates/creating-pull-requests.mdc`](lab/templates/creating-pull-requests.mdc)
to `~/.agents/rules/creating-pull-requests.mdc` and symlink
`~/.cursor/rules/creating-pull-requests.mdc` to that path so Cursor loads the
full gate on PR tasks (`alwaysApply: false`).

Do **not** copy a repo-specific branch-name gate (for example services
`am-no-ticket-…` rules) into the workshop template. Those stay on your laptop
if you need them. The workshop file only ships the Goal / Ran / Doubt packet
and draft default.

Previously this lived in three files (`pr-author-packet.mdc`,
`draft-pr-default.mdc`, and `creating-pull-requests.mdc`). They duplicated the
same template and draft default — one file is enough.

### 2. Wire every product you use

From a checkout that contains the wire script in the workshop `lab/` folder:

```bash
cd path/to/ai-workshops/workshops/customizing-agent-workflow/lab
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

This points Claude, Cursor, Gemini, and Firebender at
`~/.agents/instructions/shared.md`. Restart each product; confirm with
`/memory` (Claude), `/memory show` (Gemini), or a quote test (Cursor /
Firebender).

If Goal / Ran / Doubt lives only in a Cursor extra `.mdc` (not in `shared.md`),
also run `bash sync-personal-rules.sh` so Claude can read that extra file on
demand. That is optional.

### 3. Gemini CLI — global memory

The wire script writes `~/.gemini/GEMINI.md` from `shared.md`. After edits to
`shared.md`, re-run `wire-personal-agents.sh`, then `/memory refresh` and
`/memory show`.

### 4. Firebender — personal rules

The wire script writes `~/.firebender/rules/personal-instructions.mdc`. Verify
with `ls -l ~/.firebender/rules/*.mdc`, then ask a new Firebender chat to quote
the Precedence line.

### 5. Smoke test

Same prompt twice. Do not open or push a PR.

1. App repo with no PR headings: `## Goal`, `## Ran`, `## Doubt`.
2. This clone open: `## What`, `## Why this repo`, `## Verify`.

---

## Cursor Cloud Agents — personal rules do not apply

When you start a task from the **Agents window** or the **Cloud Agents dashboard**,
the agent runs on a remote Ubuntu VM. That VM:

- Clones the repo at the requested commit
- Loads **project** rules from `.cursor/rules/` in the clone
- Loads **`AGENTS.md`** (including nested files)
- May load **Team Rules** from the Cursor dashboard (team/enterprise)
- Does **not** load `~/.agents/` or `~/.cursor/rules/` from your laptop
- Does **not** load Cursor User Rules stored only on your machine

So personal `creating-pull-requests.mdc` affects **local desktop Agent chat
only**, not Cloud Agent PRs, unless you copy the same instructions into the repo
or team layer.

---

## What to do for Cloud Agent PRs

Use one or more of these **per repo** where Cloud Agents create or edit PRs.

### Option A — Project rule (recommended)

Commit `.cursor/rules/creating-pull-requests.mdc` or
`.cursor/rules/pr-author-packet.mdc` in the repo with `alwaysApply: true` and
the same Goal / Ran / Doubt template. Cloud Agents clone the repo and load
project rules the same way local Agent does for committed rules.

Minimal frontmatter:

```yaml
---
description: PR descriptions must use Goal / Ran / Doubt author packet
alwaysApply: true
---
```

Copy the body from your personal `~/.cursor/rules/creating-pull-requests.mdc`.

### Option B — AGENTS.md section

Cloud setup docs recommend a **Cursor Cloud specific instructions** section in
`AGENTS.md`. Add a short **Pull request descriptions** block with the three
required headings and the template.

This loads even when you have no `.cursor/environment.json`.

### Option C — GitHub PR template

Add `.github/pull_request_template.md` with Goal / Ran / Doubt headings. GitHub
pre-fills the PR body when anyone opens a PR — including after a Cloud Agent
pushes a branch. This also covers humans who open PRs without an agent.

### Option D — Team Rules (Cursor dashboard)

On Team or Enterprise plans, paste the author-packet requirements into
**Team Rules** in the Cursor dashboard. Team Rules apply across repos for
team members (including Cloud Agent runs). Use **Enforce** if the org wants
opt-out disabled.

### Option E — Create-PR skill

If the repo has `.agents/skills/create-pr/SKILL.md`, embed the template in the
skill body so any agent that follows the skill gets the format. Many Nuuly repos
route PR creation through this skill instead of raw `gh pr create`.

---

## Which layer to use when

| You want… | Use |
|-----------|-----|
| Your machine only, all repos | `~/.agents/instructions/shared.md` + `wire-personal-agents.sh` |
| One repo, local + Cloud | Commit repo `.cursor/rules/` rule **or** `AGENTS.md` section |
| All engineers + Cloud, one org | Team Rules + optional org `.github` PR template |
| Humans without agents | `.github/pull_request_template.md` |

You can stack layers: personal rule for local speed, repo rule for Cloud parity,
GitHub template for humans.

---

## Promotion ladder

| Kind | Destination |
|------|-------------|
| Personal habit (draft PRs, author packet locally) | `~/.agents/instructions/shared.md` + `wire-personal-agents.sh` |
| Same habit in Cloud | Repo `.cursor/rules/` or `AGENTS.md` |
| Whole team | Team Rules + PR template |
| Curriculum / how-to | This file + [lab/README.md](lab/README.md) |

Do not commit `~/.cursor/rules/*` unless you intend to share those exact prefs
with the team. For Cloud parity, copy content into the repo instead of symlinking
from home.

---

## Related files on this machine

| Path | Loads in |
|------|----------|
| `~/.agents/instructions/shared.md` | Canonical personal prefs (all local products via wrappers) |
| `~/.cursor/rules/personal-instructions.mdc` | Cursor wrapper |
| `~/.cursor/rules/creating-pull-requests.mdc` | Goal / Ran / Doubt gate (`alwaysApply: false`; Lab A symlink) |
| `~/.claude/CLAUDE.md` | Claude — `@` import of `shared.md` |
| `~/.gemini/GEMINI.md` | Gemini CLI (global) |
| `~/.firebender/rules/personal-instructions.mdc` | Firebender |

After editing `shared.md`, re-run `bash wire-personal-agents.sh` from the
workshop `lab/` folder if you use Cursor, Gemini, or Firebender (not required
for Claude `@` import after content-only edits).
