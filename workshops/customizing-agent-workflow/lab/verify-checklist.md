# Verify checklist — Customizing Your Agent Workflow

Mark **N/A** for products you do not use. All three steps must pass for each
product you verify.

| Check | Pass |
|-------|------|
| `~/.agents/instructions/shared.md` starts with Precedence line | Yes / No |
| `~/.agents/` is a git repo; `.gitignore` present; no secrets committed | Yes / No |
| **Wire** — `wire-personal-agents.sh --check` ok for products you use | Yes / No |
| **Cursor** — Precedence quote in new Agent chat | Yes / No / N/A |
| **Claude** — `/memory` lists personal `CLAUDE.md` or the `@` import | Yes / No / N/A |
| **Gemini CLI** — `/memory show` lists `GEMINI.md` and `AGENTS.md` | Yes / No / N/A |
| **Firebender** — `ls -l ~/.firebender/rules/*.mdc` ok; chat quotes Precedence | Yes / No / N/A |
| **Smoke test** — repo `AGENTS.md` wins on commits | Yes / No |
| Products verified today | _____________ |

## Smoke test prompts

1. `Draft a PR body for my current branch.`
2. `What does AGENTS.md say about commits? Should you commit without me asking?`

Pass on prompt 2: the agent cites the **repo** rule, not only your personal habit.
