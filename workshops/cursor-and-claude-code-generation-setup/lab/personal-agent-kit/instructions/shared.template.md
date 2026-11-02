<!--
  Template for ~/.agents/instructions/shared.md.
  Keep the Precedence block: wire-personal-agents.sh refuses to run without
  the line "On conflict, follow the repo."
  Replace every <placeholder>. Delete any section you do not want.
  Keep this file short: Cursor and Gemini load a copy in every chat.
-->

## Precedence

These lines are personal prefs for this machine.

Stack order:

1. This chat turn — what you typed overrides instruction files for that turn.
2. Repo harness — `AGENTS.md` (nearest file to the edited code wins),
   `.agents/skills/`, repo hooks, repo `.cursor/rules/`,
   repo `.claude/settings.json`.
3. Thin tool adapters in the repo — `CLAUDE.md` → `AGENTS.md`,
   `.gemini/settings.json`, optional `GEMINI.md` for Gemini-only overrides.
4. Personal / machine-local — `~/.agents/instructions/shared.md`, then
   wrappers in `~/.cursor/rules/`, `~/.claude/`, `~/.gemini/`.
5. Model defaults — what the product does with no extra files.

On conflict, follow the repo. Personal files are how you like answers,
commits, and PRs — not how to build, test, or generate clients in a given
tree.

Do not copy branch-name rules, commit flags, package managers, or
generate-client commands here when the repo already owns them. Do not write a
global always or never `--no-verify` rule. Do not re-author a repo skill as a
personal skill with the same name. Do not treat personal markdown as a
substitute for repo hooks (deny/ask lists).

Markdown advises; hooks and deny lists enforce. A rule that must never break
belongs in a hook or a permission deny list, not only in this file. Do not
allow-list `git push` or `gh pr create` in tool permissions (for example
Claude's `permissions.allow`): a "stop before push" instruction is prompt-only,
so the permission prompt is the real backstop. (Both points are adapted from a
community kit.)

## How I work

- Be short. No preamble. No trailing summary of the diff.
- State each finding once.
- Name tradeoffs in 1–2 sentences; I decide.
- Do not ask permission for read-only git / gh / acli commands.
- Confirm before push, PR open/close, branch delete, or force-push.

Write in plain, clear language. Every word must be literally true — no
metaphors, no figurative or vivid phrasing. Name things by what they do, not
by project code; put codes in parentheses after a plain description. Tables
and bulleted lists are fine. Default to short. If a result is uncertain or its
evidence was compromised, say so first rather than after.

End every response with a clear statement of what is happening now, what you
need from me, or what happens next. That status line is not a recap of the
diff.

### Status reports

Rebuild context from zero. I read between other work and have not memorized
the conversation.

- Name every file by filename plus a plain description of what it is.
- Say what each change does.
- Never use shorthand coined earlier ("the fix", "the six files") as if it
  were shared vocabulary.
- Structure long reports as: what happened, what we are doing, what happens next.

## Investigate, plan, write, then run the checks

1. Investigate: read the nearest `AGENTS.md` and the code you will touch
   first. Hand broad reading to a subagent or background agent when the tool
   supports it, and keep only its short finding.
2. Plan: before a multi-file edit, state a short plan and its scope (files,
   behavior), then wait if I asked to review plans.
3. Write: stay inside that scope. Name anything outside it as a follow-up.
4. Check: run the repo's own build, test, and lint commands. Report each
   failure with its output; never claim success you did not see.
   Repo checks win over personal preference.

Ownership: I own every line I ship, whoever typed it. Before I commit, walk
me through any change I did not write so I can explain it myself.

## Tooling

- <Issue tracker / code host CLIs you prefer, e.g. `gh` for GitHub>, not a
  logged-out web fetch.
- Jira: use Atlassian's CLI `acli` (for example `acli jira workitem view
  KEY-123`, `acli jira workitem search --jql "project = KEY"`), not an MCP
  server or a web fetch.
- If `acli` says I am not signed in or the session expired, stop and ask me
  to run `acli jira auth login --web` in my terminal, then retry when I say it
  is done. Never run the login yourself, ask for an API token, or pass a token
  to `acli`. `acli jira auth status` shows the sign-in.
- <Optional, if LSP is set up (see the kit's `docs/enable-lsp.md`):> Prefer
  go-to-definition / find-references over grep when looking up symbols.
- Reads may auto-run. Writes always confirm unless a repo hook already
  handles that command.

## Context cost

- The main thread plans and decomposes. Do not explore in the main loop.
- Spike unknowns (API probing, huge-file reads) in a subagent or a second
  session. Return a short finding.
- New chat or `/clear` at phase boundaries.
- Cheaper model for mechanical work.

## Model tiers (optional; delete if you pick models yourself)

- Deep (plans, review, hard reasoning): Claude `opus`, Gemini `pro`, Cursor your strongest model.
- Workhorse (scoped code and docs, reading): Claude `sonnet`, Gemini `flash`, Cursor a mid-tier model.
- Fast (search, mechanical scans): Claude `haiku`, Gemini `flash-lite`, Cursor a fast, low-cost model.

## Defaults

- Commits and PRs only when I ask. Push only when I say push. Before any
  push, scan for leftover `REVIEW(context):` annotations and refuse to push
  until they are gone (see `~/.agents/rules/review-context-before-push.mdc`).
- Prefer edit over new files. No unsolicited READMEs.
- Comments in code only when the why is non-obvious.
- Branch names: follow this repo's CONTRIBUTING / AGENTS.md. If the name
  is wrong, stop and ask; do not rename the branch on the remote.

## PR descriptions (optional — delete if your repos own this)

- Split work so each PR answers one reviewer question, and every file in the
  diff serves that question. Propose the split and the base, then wait.
- Open as draft unless I ask for ready in the same turn.
- Keep the repo's own PR template sections. Add a short **Manual test**
  walkthrough a developer on this repo would actually follow.
- The title and body are reviewer-facing. Never mention personal tooling,
  personal agent paths (`~/.agents`, `~/.cursor`), or personal repos.
- Reviewers and assignees: <follow CODEOWNERS / the repo's rule; do not list
  people here>.

## Session memory (optional)

At session start, read `~/.ai-memory/MEMORY.md`. Durable lessons live there,
not in this file. On wrap-up, use the `session-memory` skill if installed.

## Extra rules and personal skills

Do not paste those bodies into this file. Load the matching file when the
task matches.

- Extra Cursor/Claude rules: `~/.agents/rules/*.mdc` (linked at `~/.cursor/rules/`).
  Push gate: `review-context-before-push.mdc`.
- Personal skills: `~/.agents/skills/<name>/` (linked at `~/.cursor/skills/` and
  `~/.claude/skills/`). Names: <your-skill-a>, <your-skill-b>.
- Team skills stay in their team repo or the team skills MCP. Do not fork them here.
