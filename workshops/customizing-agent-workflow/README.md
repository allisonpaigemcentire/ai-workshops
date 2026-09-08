# Customizing Your Agent Workflow

Set up **personal** agent preferences so Cursor, Claude Code, Gemini CLI,
Antigravity, and Firebender work the way you work — without overriding the repo
harness (`AGENTS.md`, skills, hooks, rules) that already exists in your
application repos.

- **Audience:** engineers who use one or more AI coding tools daily
- **Duration:** 60 minutes
- **Prerequisites:** an application repo with `AGENTS.md`; Cursor, Claude Code,
  Gemini CLI, and/or Firebender installed on your machine
- **What participants leave with:** personal pref files on disk, the sync script
  for Cursor ↔ Claude, and a completed verify checklist for each product they use

## Contents of this folder

| File | Audience | Contents |
|------|----------|----------|
| [handout.md](handout.md) | Participant | Full guide: precedence, per-tool loading, verify steps, Cloud promotion |
| [lab/](lab/) | **Participant clone target** | Templates, `sync-personal-rules.sh`, verify checklist |
| [agenda-60min.md](agenda-60min.md) | Facilitator | Run-of-show |
| [facilitator-guide.md](facilitator-guide.md) | Facilitator only | Timed labs, exit checks, dry-run checklist |
| [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) | Both | 33-slide deck with speaker notes |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Both | Goal / Ran / Doubt PR example and Cursor Cloud workaround |

## Running this workshop

1. Participants clone the lab folder (see [lab/README.md](lab/README.md)).
2. Facilitator opens [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) in a browser.
3. Follow [agenda-60min.md](agenda-60min.md) and [facilitator-guide.md](facilitator-guide.md).
4. Lab A: write personal prefs. Lab B: wire and verify. Lab C: smoke test that
   repo `AGENTS.md` wins on commits.

## Takeaway line

Personal prefs fill gaps on this machine. Repo files still win on conflict.

## Participant clone command

```bash
git clone https://github.com/allisonpaigemcentire/ai-workshops.git
cd ai-workshops/workshops/customizing-agent-workflow/lab
```

Then follow [lab/README.md](lab/README.md).
