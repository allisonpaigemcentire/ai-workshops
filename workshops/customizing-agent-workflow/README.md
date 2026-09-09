# Customizing Your Agent Workflow

Set up **personal** agent preferences so Cursor, Claude Code, Gemini CLI,
Antigravity, and Firebender work the way you work — without overriding the repo
harness (`AGENTS.md`, skills, hooks, rules) that already exists in your
application repos.

- **Audience:** engineers who use one or more AI coding tools daily
- **Duration:** 60 minutes
- **Prerequisites:** an application repo with `AGENTS.md`; Cursor, Claude Code,
  Gemini CLI, and/or Firebender installed on your machine
- **What participants leave with:** `~/.agents/instructions/shared.md` on disk,
  product wrappers from `wire-personal-agents.sh`, and a completed verify
  checklist for each product they use

## Contents of this folder

| File | Contents |
|------|----------|
| [handout.md](handout.md) | Full guide: precedence, per-tool loading, `~/.agents/` source of truth, verify steps, Cloud promotion |
| [lab/](lab/) | Templates, `wire-personal-agents.sh`, verify checklist |
| [example/](example/) | Sample finished personal setup (`~/.agents/` + product wrappers) |
| [customizing-your-agent-workflow-slides-draft-2.html](customizing-your-agent-workflow-slides-draft-2.html) | **Live deck (Draft 2):** 26 slides — practices 1–11, Labs A–C, then best-practice sources |
| [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) | Draft 1 archive: 44 slides with pull quotes, skip list, and take-home slides 38–41 |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Goal / Ran / Doubt PR example and Cursor Cloud workaround |

All participant and presenter files for this workshop live in this folder.

## Getting started

1. Clone the lab folder (see [lab/README.md](lab/README.md)).
2. Open [customizing-your-agent-workflow-slides-draft-2.html](customizing-your-agent-workflow-slides-draft-2.html) in a browser.
3. Follow [handout.md](handout.md) and [lab/README.md](lab/README.md) for setup and verify steps.

## Takeaway line

Personal prefs fill gaps on this machine. Repo files still win on conflict.
Edit `~/.agents/instructions/shared.md` once. Point each product at that file.

## Participant clone command

```bash
git clone https://github.com/allisonpaigemcentire/ai-workshops.git
cd ai-workshops/workshops/customizing-agent-workflow/lab
```

Then follow [lab/README.md](lab/README.md).
