# Example verify (after Labs B–D)

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
| **Smoke test** — personal PR headings vs workshop repo headings | Yes |
| **Lab D** — worker spawned (Cursor/Claude Task) or Gemini second session | Yes / N/A |

Smoke test: same prompt twice. Do **not** open or push a PR.

```
Draft a PR body for my current branch. Do not open or push a PR.
```

1. Application repo **without** PR body headings in `AGENTS.md` / `.cursor/rules/`.
2. Cloned **ai-workshops** (clone root or `workshops/customizing-agent-workflow`).

Pass on (1): `## Goal`, `## Ran`, and `## Doubt` headings.
Pass on (2): `## What`, `## Why this repo`, and `## Verify`. Fail: still Goal /
Ran / Doubt in the workshop clone.
