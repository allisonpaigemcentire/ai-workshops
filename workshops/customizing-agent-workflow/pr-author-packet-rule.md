# PR author-packet rule — personal setup and Cloud workaround

How to make agents use **Goal / Ran / Doubt** (plus optional **Test plan**) in
every pull request description on your machine, and what to do when the agent
runs in **Cursor Cloud** instead of local desktop chat.

Related: [lab/README.md](lab/README.md),
[pr-review-ai deck](../../presentations/pr-review-ai/pr-review-ai-slides.html).

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

Personal rules live on your machine. They apply across all repos you open
locally. They do **not** commit to git.

### 1. Cursor — canonical source

One file covers author packet, draft default, full `gh pr create` workflow, and
`r15-services-customer` branch gates:

| File | Role |
|------|------|
| `creating-pull-requests.mdc` | Goal / Ran / Doubt body, draft-by-default, `gh` workflow, branch-name hard gate, Cloud workaround notes |

Use `alwaysApply: false` with a clear `description` so the rule loads when PR
work is relevant, not every session (see handout section 5 — keep context lean).

`creating-pull-requests.mdc` step 0 is a hard gate for `r15-services-customer`:
do not create a branch, push, or open a PR until the name is valid. No ticket:
`am-no-ticket-<slug>` with hyphens only (copy
`am-no-ticket-cx-agents-4-uncovered-context`). Ticketed:
`am/<ticket>-<description>` per that repo's `CONTRIBUTING.md`. Never
`am/no-ticket/...` and never the GitHub login `allisonpaigemcentire`. If the
current name is wrong, stop and ask. Do not use GitHub's branch-rename API.

Previously this lived in three files (`pr-author-packet.mdc`,
`draft-pr-default.mdc`, and `creating-pull-requests.mdc`). They duplicated the
same template and draft default — one file is enough.

### 2. Claude Code — symlink bridge

From a checkout that contains the sync script in the workshop `lab/` folder:

```bash
cd path/to/ai-workshops/workshops/customizing-agent-workflow/lab
bash sync-personal-rules.sh
bash sync-personal-rules.sh --check
```

This mirrors each `~/.cursor/rules/*.mdc` to `~/.claude/rules/<stem>.md`
**except** stems in `.claude-exclude`. Situational rules (`creating-pull-requests`,
`cody-review-before-commit`) stay out of Claude’s always-loaded set; managed
`~/.claude/CLAUDE.md` carries a short PR/commit summary and instructs Claude
to read the full `.mdc` when that work starts. Restart Claude Code; confirm
with `/memory`.

### 3. Gemini CLI — global memory

Add the same PR body requirements to `~/.gemini/GEMINI.md`. Run `/memory refresh`
in an active Gemini CLI session after edits, then `/memory show` to confirm
`GEMINI.md` appears in the loaded list.

### 4. Firebender — personal rules

Add the same PR body requirements to `~/.firebender/rules/` (copy or symlink
from `~/.cursor/rules/creating-pull-requests.mdc`). Verify with
`ls -l ~/.firebender/rules/*.mdc`, then ask a new Firebender chat to quote
the Precedence line from that file.

### 5. Smoke test

Ask local Agent: "Draft a PR body for my current branch." Confirm output has
`## Goal`, `## Ran`, and `## Doubt`.

---

## Cursor Cloud Agents — personal rules do not apply

When you start a task from the **Agents window** or the **Cloud Agents dashboard**,
the agent runs on a remote Ubuntu VM. That VM:

- Clones the repo at the requested commit
- Loads **project** rules from `.cursor/rules/` in the clone
- Loads **`AGENTS.md`** (including nested files)
- May load **Team Rules** from the Cursor dashboard (team/enterprise)
- Does **not** load `~/.cursor/rules/` from your laptop
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
| Your machine only, all repos | `~/.cursor/rules/creating-pull-requests.mdc` + sync script + `~/.gemini/GEMINI.md` |
| One repo, local + Cloud | Commit repo `.cursor/rules/` rule **or** `AGENTS.md` section |
| All engineers + Cloud, one org | Team Rules + optional org `.github` PR template |
| Humans without agents | `.github/pull_request_template.md` |

You can stack layers: personal rule for local speed, repo rule for Cloud parity,
GitHub template for humans.

---

## Promotion ladder

| Kind | Destination |
|------|-------------|
| Personal habit (draft PRs, author packet locally) | `~/.cursor/rules/creating-pull-requests.mdc` + `sync-personal-rules.sh` |
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
| `~/.cursor/rules/creating-pull-requests.mdc` | Cursor (PR tasks; `alwaysApply: false`) |
| `~/.claude/CLAUDE.md` | Claude — PR/commit summary; read full `.mdc` on demand |
| `~/.gemini/GEMINI.md` | Gemini CLI (global) |
| `~/.firebender/rules/*.mdc` | Firebender (personal; copy or symlink from Cursor) |

After editing personal rules, re-run `bash sync-personal-rules.sh` from the
workshop `lab/` folder if you added or removed a file (not required for
content-only edits to existing files).
