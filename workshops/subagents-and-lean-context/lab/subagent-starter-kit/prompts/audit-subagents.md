# Audit prompt: review your subagents

Run the read-only check first, from the kit folder:

```bash
bash install.sh --check
```

It reports drift in the three sample agents and lints the frontmatter of every
file in `~/.claude/agents/` and `~/.cursor/agents/`. In Claude Code v2.1.233 or
later, `claude plugin validate ~/.claude/agents` also does a full YAML parse.

Then paste the prompt below into Cursor or Claude Code, once a month or after
you add an agent. It reads, ranks and waits for you to pick.

```text
Review my subagents, read-only, and tell me what to fix or prune.
Use a subagent for the reading if you can, to keep this chat small.
Read ~/.claude/agents/ and ~/.cursor/agents/, plus .claude/agents/ and
.cursor/agents/ in this repo if they exist. Do not scan the rest of my disk.
Never print a token or other secret value.

For each agent file, check:
- Frontmatter: --- on line 1, a name in lowercase with hyphens, and a
  description. Claude Code skips a file without them and says nothing in the
  chat, so it looks like an agent that never fires.
- Description: does it say what the agent does and when to use it? Flag
  vague ones such as "helps with code".
- Overlap: which two agents would compete for the same task?
- Paths: does the body point at files or folders that no longer exist?
- Limits: is an agent meant to be read-only actually limited? That is
  tools: Read, Grep, Glob in Claude Code and readonly: true in Cursor.
- Copies: where a Claude Code and a Cursor copy share a name, have they
  drifted apart?
- Use: which ones might I never call? Ask me rather than guess.

Give me a ranked shortlist of at most 5 changes, highest impact first, each
with the file and line. Change nothing until I pick. Show a diff before
editing any file. Never commit or push.
```
