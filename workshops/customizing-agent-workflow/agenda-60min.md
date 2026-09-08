# Agenda — Customizing Your Agent Workflow (60 minutes)

**Audience:** engineers using Cursor, Claude Code, Gemini CLI, Antigravity,
and/or Firebender  
**Handout:** [handout.md](handout.md)  
**Lab:** [lab/README.md](lab/README.md)  
**Facilitator detail:** [facilitator-guide.md](facilitator-guide.md)  
**Deck:** [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html)

| Time | Segment | Goal |
|------|---------|------|
| **0:00–0:08** | **Frame** | Repo files win. Hooks stop; markdown advises. Deck slides 1–3 and 13. |
| **0:08–0:18** | **Map the stack and the gaps** | Five layers; Cloud Agents do not load `~/.cursor/rules`; Claude loads every `~/.claude/rules` file; Gemini and Firebender are not on the sync script. Deck slides 5, 15, 18–20, 26. |
| **0:18–0:28** | **Lab A — write prefs** | Write 5–10 personal lines from handout section 10. Save to `~/.cursor/rules/` (or tool-specific paths). |
| **0:28–0:45** | **Lab B — wire and verify** | Run sync script for Claude; copy/verify Gemini and Firebender. Same three-step verify per product. |
| **0:45–0:52** | **Lab C — smoke test** | Draft a PR body; ask what `AGENTS.md` says about commits. Repo rule must win. |
| **0:52–1:00** | **Exit checks + close** | Fill [lab/verify-checklist.md](lab/verify-checklist.md). Deck slides 32–33. |

## Out of scope (this cut)

Personal skills and subagents (handout sections 11–12; deck slide 31). Take-home
reading only.

## Success signal

Attendees leave with a personal file on disk and a completed verify row for each
product they use — not tip notes alone.
