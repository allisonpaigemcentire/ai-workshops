# Borrowed practices: model tiers, read-only helpers, guardrails

Four ideas adapted from a community kit of local agent optimizations. None
of them needs the installer. Take the ones that fit how you work.

1. [Match the model to the work](#1-match-the-model-to-the-work)
2. [Read-only helpers that cite file and line](#2-read-only-helpers-that-cite-file-and-line)
3. [Ask the agent to audit your setup](#3-ask-the-agent-to-audit-your-setup)
4. [Permission lessons](#4-permission-lessons)

## 1. Match the model to the work

Pin tiers, not versions. Model names change often; tier names and
self-updating aliases do not.

| Tier | Send it | Claude Code | Cursor | Gemini CLI |
|------|---------|-------------|--------|------------|
| **Deep** | Architecture, plans, review, ambiguous or correctness-critical reasoning | `opus` | Your strongest model in the picker | `pro` |
| **Workhorse** | Well-scoped code and doc writing, reading and summarizing code or docs | `sonnet` | A mid-tier model, or Composer for cheap interactive edits | `flash` |
| **Fast** | "Where is X?", breadth search, mechanical scans | `haiku` | Composer, or the built-in Explore subagent | `flash-lite` |

- Pick the cheapest tier that clears the bar. Escalate per task, not for
  the whole session.
- A rule can't switch the model of a chat that is already running. For
  mechanical work, start on the cheaper tier, or hand it to a subagent that
  runs on one.
- In a Claude Code subagent, set the tier in the frontmatter with an alias
  (`model: sonnet`). Aliases track the newest model of that tier.
  `model: inherit` uses the parent chat's model.
- In a Cursor subagent, `model:` takes `inherit` (the default) or a model
  ID from your plan's model list.
- Check your tool's model list every few months. A listed model may not be
  on your plan.

UNVERIFIED: the tier mapping is judgment from the community kit, not
vendor guidance. The Cursor column is generic on purpose, and the Gemini
aliases come from that kit, not from Gemini's own docs.

### Keep context lean

Everything in the chat is sent again on every turn, so a long session pays
for its early file reads until it ends.

- Let the main chat plan and decide. Send long reads and code exploration to
  a subagent that returns a short, cited digest (see section 2).
- Start a new chat or `/clear` at phase boundaries.
- Keep always-on files short. The cheat sheet's "Keep context lean" panel
  has the rest.

## 2. Read-only helpers that cite file and line

Two optional subagents ship in [`../examples/agents/`](../examples/agents/):

| File | Use it to | Returns |
|------|-----------|---------|
| `code-reader.md` | Understand one file, module or PR diff | Summary, structure, entry points and key functions, each with `file:line` |
| `doc-reader.md` | Answer one question from a long doc, spec or web page | A one-line answer, cited detail, and what the doc does not cover |

Why they help: the reading happens once, in a throwaway context, and only
the digest comes back. The citations let you spot-check a claim without
re-reading the source. Both are read-only: they can read and search but
cannot edit files.

They are off by default. To install them, add `--with-helpers`:

```bash
bash ~/src/personal-agent-kit/scripts/install.sh --with-helpers
```

The installer copies them into `~/.agents/examples/agents/` and links
`code-reader.md` and `doc-reader.md` into `~/.claude/agents/`. If you already
have a file or link with either name there, it is backed up to
`~/.agent-kit-backups/<time>/` first and then replaced by the link.
`uninstall.sh` removes only the links it added and puts your file back.
Add `--dry-run` to preview.

To use them:

- **Claude Code:** they load for all projects from `~/.claude/agents/`.
  Check with `/agents`. Ask for one by name:
  "Use the code-reader subagent on `src/cart/checkout.ts`."
- **Cursor:** Cursor also reads `~/.claude/agents/`, so the same links work.
  Call one with `/code-reader` or by name. The files set `readonly: true`
  for Cursor. To pick a Cursor model, copy the file into `~/.cursor/agents/`
  and change `model: sonnet` to `inherit` or a Cursor model ID; that copy
  wins over the one in `~/.claude/agents/`.
- **Gemini CLI:** not covered by these examples.

To copy them by hand instead (for example into one repo's
`.claude/agents/`), use `cp -n`, which never overwrites a file you already
have:

```bash
mkdir -p .claude/agents
cp -n ~/src/personal-agent-kit/examples/agents/*.md .claude/agents/
```

UNVERIFIED: whether Cursor maps the `sonnet` alias to a model, and whether
Claude Code ignores the Cursor-only `readonly` field without a warning.

## 3. Ask the agent to audit your setup

Open the kit folder (or your home folder) in Claude Code, Cursor or Gemini
CLI and paste:

```text
Review my personal agent setup and the way I work, read-only, and find ways
to optimize it. Use a subagent for the reading if you can, to keep this chat
small. Never print a token or other secret value.

Look at: ~/.agents/instructions/shared.md, ~/.agents/rules/,
~/.claude/CLAUDE.md, ~/.claude/settings.json, ~/.claude/agents/,
~/.cursor/rules/, ~/.cursor/agents/, ~/.gemini/GEMINI.md and
~/.gemini/settings.json. Ask me which repos to include; do not scan my disk.

Compare them with docs/borrowed-practices.md in this kit: model tiers,
lean context, read-only helpers that cite file and line, and the permission
lessons. For each idea, say whether it is in place, partly in place, missing
or not a fit, and cite the file and line.

Give me a ranked shortlist of at most 7 changes, highest impact first. For
each: what to change, why it helps me, and which file. Change nothing until
I pick. Show a diff before editing any file. Never commit or push.
```

Re-run it after you change your setup or a tool ships a new feature.

## 4. Permission lessons

Text rules only advise. Hooks and permission allow and deny lists enforce,
so check that they really match what you think.

- **Keep `git push` and `gh pr create` off every allow-list.** A prompt
  that says "stop before push" is not a guardrail when settings allow the
  push. Any agent that can run shell commands could push without asking.
- **`git -C <path>` slips past prefix rules.** `Bash(git diff *)` does not
  match `git -C ../other-repo diff`. Allow rules miss it, so you get extra
  prompts; add `git -C *` patterns for the read commands you want allowed.
  A deny rule written as a prefix may miss it the same way (UNVERIFIED for
  deny rules: test yours).
- **Match safety patterns against the whole value.** A branch guard that
  checks for a name starting with `release/` never fires once a prefix such
  as `user/` is added. Match "contains `release`" instead.
- **Test every guard with a known-bad input.** After you add a rule, deny
  entry or hook, try one thing it should stop and confirm it stops it. For
  example, ask the agent to run `git -C . push --dry-run` and check that you
  get a prompt or a refusal. For the push gate, add a review-context
  annotation on a scratch branch and confirm the agent refuses to push.
- **Audit config changes like code.** Ask a fresh chat or a read-only
  subagent to review a settings or hook change against your live
  `settings.json` before you rely on it.
