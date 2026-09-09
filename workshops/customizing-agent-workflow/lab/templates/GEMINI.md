# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict.
<!-- managed-by: wire-personal-agents -->

Follow `~/.agents/instructions/shared.md`. Re-run `wire-personal-agents.sh`
after you edit that file so this copy stays current.

<!-- canonical-shared.md -->

## Precedence

Repo `AGENTS.md`, `.agents/skills/`, repo hooks, and repo rules win.
These lines are personal prefs for this machine. On conflict, follow the repo.

## How I work

- Be short. No preamble. No trailing summary of the diff.
- State each finding once.
- Name tradeoffs in 1–2 sentences; I decide.
- Do not ask permission for read-only git / gh / acli.
- Confirm before push, PR open/close, branch delete, or force-push.

## Tooling

- GitHub and Jira: `gh` and `acli`, not a logged-out web fetch.
- Reads may auto-run. Writes always confirm unless a repo hook already
  handles that command.

## Context cost

- The main thread plans and decomposes. Do not explore in the main loop.
- Spike unknowns (API probing, huge-file reads) in a subagent or a second
  session. Return a short finding.
- New chat or `/clear` at phase boundaries.
- Cheaper model for mechanical work.

## Defaults

- Commits and PRs only when I ask. Push only when I say push.
- Prefer edit over new files. No unsolicited READMEs.
- Comments in code only when the why is non-obvious.
- Branch names: follow this repo's CONTRIBUTING / AGENTS.md. If the name
  is wrong, stop and ask; do not rename the branch on GitHub.
<!-- /managed-by: wire-personal-agents -->
