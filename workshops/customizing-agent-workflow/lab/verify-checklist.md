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
| **Smoke test** — personal PR headings vs workshop repo headings | Yes / No |
| **Lab D** — worker spawned (Cursor/Claude Task) or Gemini second session | Yes / No / N/A |
| Products verified today | _____________ |

## Smoke test prompts

Same prompt twice. Do **not** open or push a PR. Switch the open folder
between runs.

```
Draft a PR body for my current branch. Do not open or push a PR.
```

1. Application repo **without** PR body headings in `AGENTS.md` / `.cursor/rules/`.
2. Cloned **ai-workshops** (clone root or `workshops/customizing-agent-workflow`, not `lab/` alone).

Pass on (1): `## Goal`, `## Ran`, and `## Doubt`.
Pass on (2): `## What`, `## Why this repo`, and `## Verify`. Fail: still Goal / Ran / Doubt in the workshop clone.
