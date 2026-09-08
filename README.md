# AI Workshops

This repository holds facilitator and participant material for hands-on AI workshops.
It is separate from any internal planning or strategy repository — everything under
`workshops/` is written to be shared with, and cloned by, workshop participants.

## Layout

```
ai-workshops/
  templates/
    workshop-template/       # copy this folder to start a new workshop
    lab-starter-template/    # minimal starter repo scaffold for a hands-on lab
  workshops/
    <workshop-slug>/         # one folder per workshop
  _archive/                  # retired workshops, kept for history
```

## Index of workshops

| Workshop | Audience | Duration | Status |
|---|---|---|---|
| [customizing-agent-workflow](workshops/customizing-agent-workflow/) | Engineers using Cursor, Claude, Gemini, Firebender | 60 min | Draft |
| [git-worktrees](workshops/git-worktrees/) | Engineers using AI agents who need parallel branches | Hands-on | Available |

## Adding a new workshop

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Naming convention

Workshop folders use a descriptive kebab-case name that says what the workshop is
about (for example `claude-code-and-cursor`, `ios-vqa-claude-simulator`) — not a
project codename or auto-generated slug.

## Facilitator material vs. participant material

Each workshop folder keeps facilitator-only material (facilitator guide, answer key,
dry-run notes) at the workshop root. Only the `lab/` subfolder is what participants
are ever pointed at to clone or open. Do not put facilitator-only material inside
`lab/`.

## Labs that need their own git history

Some workshops (for example, one that teaches git branching or worktrees) need
participants to have their own real git history to work in, not just a folder of
files. For those, do not nest a second git repository inside this repo. Instead,
push a separate, dedicated repository (for example `ai-workshops-lab-<slug>`) that
participants can clone directly by URL, and link to it from that workshop's README.
