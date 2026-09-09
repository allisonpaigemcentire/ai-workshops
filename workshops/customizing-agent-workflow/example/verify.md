# Example verify (after Labs B and C)

Filled-in version of `lab/verify-checklist.md` for this sample setup.
On your machine, mark N/A for products you do not use.

| Check | Pass |
|-------|------|
| `~/.agents/instructions/shared.md` starts with Precedence line | Yes |
| `~/.agents/` is a git repo; `.gitignore` present; no secrets committed | Yes |
| **Wire** — `wire-personal-agents.sh --check` ok for products you use | Yes |
| **Cursor** — Precedence quote in new Agent chat | Yes / N/A |
| **Claude** — `/memory` lists personal `CLAUDE.md` or the `@` import | Yes / N/A |
| **Gemini CLI** — `/memory show` lists `GEMINI.md` and `AGENTS.md` | Yes / N/A |
| **Firebender** — `ls -l ~/.firebender/rules/*.mdc` ok; chat quotes Precedence | Yes / N/A |
| **Smoke test** — repo `AGENTS.md` wins on commits | Yes |

Smoke test prompts (run in an **application** repo that already has `AGENTS.md`):

1. `Draft a PR body for my current branch.`
2. `What does AGENTS.md say about commits? Should you commit without me asking?`

Pass on prompt 2: the agent cites the repo. Fail: it follows only personal
habit and ignores `AGENTS.md`.
