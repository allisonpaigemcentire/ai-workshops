# Cheat sheet: Subagents and lean context

The printable one-page version is `lab/subagent-starter-kit/companion/lean-context-cheat-sheet.html` (prints on one letter landscape page).

## Install, check, undo

```bash
mkdir -p ~/src && unzip ~/Downloads/subagent-starter-kit.zip -d ~/src
bash ~/src/subagent-starter-kit/install.sh --dry-run
bash ~/src/subagent-starter-kit/install.sh
bash ~/src/subagent-starter-kit/install.sh --check
bash ~/.subagent-starter-kit/uninstall.sh
```

## Use them

| Tool | To be sure it runs |
|---|---|
| Cursor | `/code-reader explain src/main.ts` |
| Claude Code | `@agent-code-reader explain src/main.ts`, or type `@` and pick it |
| Either | "Use the doc-reader subagent to ..." lets the main agent decide |

Write the task like a ticket: goal, paths to read, limits, and the shape of the answer.

## Maintain and audit

- The description decides routing. Say what the agent does and when to use it.
- Keep two or three focused agents.
- `install.sh --check` reports drift and lints every agent file. Full parse in Claude Code: `claude plugin validate ~/.claude/agents`.
- Paste `prompts/audit-subagents.md` to get a ranked shortlist of fixes.

## Habits

| You want to | Cursor | Claude Code |
|---|---|---|
| Start clean for a new task | New chat (CLI: `/clear` or `/new`) | `/clear` |
| Shrink a long chat | Summarizes automatically near the limit (CLI: `/summarize`) | `/compact` with a focus |
| Bring old work forward | `@Chats`; CLI `/fork` | `/rename`, then `claude --resume` |
| Ask a side question | `/side` | `/btw` |
| See what fills context | The context ring | `/context` |

After two failed corrections on the same mistake, start fresh with a better prompt. Ask for a short handoff note first.

## Where to get help

Friday AI Adoption Drop in Q&A, 9:30 AM ET. The join link is in the calendar invite.
