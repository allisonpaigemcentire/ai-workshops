# Subagents and lean context for Cursor and Claude Code

This workshop has two parts. Part 1 installs three read-only subagents with one command, then shows how to use them, maintain them and audit them. Part 2 explains why long sessions give worse answers and the habits that keep context lean: a fresh chat per task, focused compaction, sending exploration to a subagent, and short always-on files.

- **Audience:** engineers using Cursor or Claude Code locally
- **Duration:** about 45 minutes
- **Prerequisites:** Cursor or Claude Code installed and signed in, a terminal with bash, and the kit zip downloaded (see `lab/README.md`)
- **What participants leave with:** three working subagents in their tools, a check they can re-run any time (`install.sh --check`), an audit prompt for the agents they already have, and a one-page cheat sheet of lean-context habits

## Contents of this folder

- `agenda-45min.md`: run-of-show for the session
- `facilitator-guide.md`: facilitator-only timing notes, answer key and common questions
- `cheat-sheet.md`: one-page reference participants can keep
- `sources.md`: links and quotes behind every claim in part 2 and the tool facts in part 1
- `lab/`: the starter kit, its zip, and the participant instructions
  - `lab/subagent-starter-kit/companion/subagents-and-lean-context.html`: the deck
  - `lab/subagent-starter-kit/companion/lean-context-cheat-sheet.html`: the printable cheat sheet
