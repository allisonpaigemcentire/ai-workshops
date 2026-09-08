# Verify checklist — Customizing Your Agent Workflow

Mark **N/A** for products you do not use. All three steps must pass for each
product you verify.

| Check | Pass |
|-------|------|
| Personal file starts with Precedence line | Yes / No |
| **Cursor** — distinctive line or rule list in new Agent chat | Yes / No / N/A |
| **Claude** — `sync-personal-rules.sh --check` ok; `/memory` lists rules | Yes / No / N/A |
| **Gemini CLI** — `/memory show` lists `GEMINI.md` and `AGENTS.md` | Yes / No / N/A |
| **Firebender** — `ls -l ~/.firebender/rules/*.mdc` ok; chat quotes Precedence | Yes / No / N/A |
| **Smoke test** — repo `AGENTS.md` wins on commits | Yes / No |
| Products verified today | _____________ |

## Smoke test prompts

1. `Draft a PR body for my current branch.`
2. `What does AGENTS.md say about commits? Should you commit without me asking?`

Pass on prompt 2: the agent cites the **repo** rule, not only your personal habit.
