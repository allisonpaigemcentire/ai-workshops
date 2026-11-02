# Facilitator guide: Subagents and lean context

This file is facilitator-only. Do not point participants at it or copy it into `lab/`.

## Timing notes

- The full script runs about 47 minutes. To fit 45, shorten slide 7 (routing) to one sentence and skip reading the context-checker file aloud on slide 4.
- Slide 5 (install) is where people fall behind. Start the install while you talk through the five steps, and keep the dry run on screen.
- If time is short in part 2, keep slides 11, 14 and 16. Slides 13 and 15 can be summarized in one minute each.

## Answer key

**Install (slide 5).** A fresh install prints the plan with `add` for six files (three per tool), asks once, then prints the `/code-reader` and `@agent-code-reader` hints and the Check and Undo lines. Running it again prints "Nothing to change."

**Use (slide 6).** In Cursor, `/context-checker check my current branch ...` runs the subagent. In Claude Code, `@agent-context-checker ...` or picking "context-checker (agent)" from the `@` list runs it. An @-mention without the `agent-` prefix is not the documented form.

**Check (slide 9).** `install.sh --check` prints `ok` for each kit agent and "No drift. No lint problems." on a clean machine. To demo a `LINT` line, copy an agent and delete its `description:` line, then run the check again.

**Audit prompt (slide 9).** Expect a ranked shortlist of at most five changes with file and line, and no edits until the participant picks one.

## Common questions / sticking points

- **"Claude Code does not see the agent."** If `~/.claude/agents/` did not exist when the session started, restart Claude Code once. Otherwise run `install.sh --check` and look for a `LINT` line.
- **"Cursor does not show it."** Start a new chat. Cursor also reads `~/.claude/agents/`; when names conflict, the `.cursor/` copy wins, which is why the kit installs a Cursor copy too.
- **"I already have an agent called code-reader."** The installer leaves it alone and says so. `--force` replaces it after a backup, and uninstall restores it.
- **"Typing @agent- shows files, not agents."** Keep typing and send; the mention still resolves. Or type `@` and pick the agent from the list.
- **"Should I make ten subagents?"** Start with two or three. Five running in parallel cost about five times the tokens of one.
- **"Is a 1M-token window not enough?"** Running out is rare now. The reason to stay lean is answer quality and cost: recall drops as context grows, and stale history is paid for on every request.
- **"Which numbers are solid?"** The tool behaviour comes from the Cursor and Claude Code docs. Chroma (2025) and Laban et al. (2025) are recent measured studies. Liu et al. is early evidence from 2023 models; say so if asked.
