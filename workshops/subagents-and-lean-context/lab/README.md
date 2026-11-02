# Lab: Subagents and lean context

Participant-facing instructions. Everything you need is in `subagent-starter-kit/`, also packed as `subagent-starter-kit.zip`.

## Setup

1. Download the kit: [subagent-starter-kit.zip](subagent-starter-kit.zip), or directly from <https://github.com/allisonpaigemcentire/ai-workshops/raw/main/workshops/subagents-and-lean-context/lab/subagent-starter-kit.zip>.
2. Unzip it and preview the install. The dry run changes nothing.

   ```bash
   mkdir -p ~/src && unzip ~/Downloads/subagent-starter-kit.zip -d ~/src
   bash ~/src/subagent-starter-kit/install.sh --dry-run
   ```

3. Install. It asks once before it writes anything.

   ```bash
   bash ~/src/subagent-starter-kit/install.sh
   ```

   Only one tool? Add `--tools=cursor` or `--tools=claude`. Claude Code: restart once if `~/.claude/agents/` is new. Cursor: if an agent does not show up yet, start a new chat.

## Exercises

1. **Run one on purpose.** Open a repo you work in. In Cursor, type `/code-reader explain <a file you know>`. In Claude Code, type `@agent-code-reader explain <a file you know>`, or type `@` and pick code-reader from the list. Open one `path:line` it cites and check it.
2. **Check before a PR.** On a branch with changes, ask `context-checker` (with `/context-checker` or `@agent-context-checker`) to check the branch against the repo's `AGENTS.md`, `CLAUDE.md` and skills.
3. **Check and audit.** Run `bash ~/src/subagent-starter-kit/install.sh --check`. Then paste `subagent-starter-kit/prompts/audit-subagents.md` into either tool and read the shortlist. Change nothing yet.
4. **See your context.** In Cursor, click the context ring next to the prompt. In Claude Code, run `/context`. Note the biggest category before you type anything.
5. **Start fresh with a handoff.** In a long chat, ask for a short handoff note (the prompt is on slide 16), start a new chat, and paste it.

## Undo

```bash
bash ~/.subagent-starter-kit/uninstall.sh
```

The deck is `subagent-starter-kit/companion/subagents-and-lean-context.html` and the printable cheat sheet is `subagent-starter-kit/companion/lean-context-cheat-sheet.html`.
