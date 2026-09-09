# Customizing Your Agent Workflow

Set up **personal** agent preferences so Cursor, Claude Code, Gemini CLI,
Antigravity, and Firebender work the way you work — without overriding the repo
harness (`AGENTS.md`, skills, hooks, rules) that already exists in your
application repos.

- **Audience:** engineers who use one or more AI coding tools daily
- **Duration:** 60 minutes
- **Prerequisites:** an application repo with `AGENTS.md`; Cursor, Claude Code,
  Gemini CLI, and/or Firebender installed on your machine
- **What participants leave with:** `~/.agents/instructions/shared.md` on disk
  and product wrappers from `wire-personal-agents.sh`

## Contents of this folder

| File | Contents |
|------|----------|
| [AGENTS.md](AGENTS.md) | Repo harness: commits; PR body is What / Why this repo / Verify (Lab C) |
| [handout.md](handout.md) | Full guide: precedence, per-tool loading, `~/.agents/` source of truth, verify steps, Cloud promotion |
| [lab/](lab/) | Templates, `wire-personal-agents.sh`, walkthrough |
| [example/](example/) | Sample finished personal setup (`~/.agents/` + product wrappers). Start at [example/walkthrough.md](example/walkthrough.md) |
| [slides.html](slides.html) | **Live deck:** 17 slides, no speaker notes — clone, practices, Labs A–D, sources |
| [customizing-your-agent-workflow-slides-draft-3.html](customizing-your-agent-workflow-slides-draft-3.html) | Same deck with speaker notes (facilitator) |
| [handout-laptop-vs-repo-adapters.md](handout-laptop-vs-repo-adapters.md) | Why the laptop wire script is allowed and a repo SessionStart wrapper script is not |

All participant and presenter files for this workshop live in this folder.

## Getting started

1. Clone the lab folder (see [lab/README.md](lab/README.md)).
2. Open [slides.html](slides.html) in a browser.
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
