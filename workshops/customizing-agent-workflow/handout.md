# Customizing Your Agent Workflow

A practical guide for Nuuly engineers. Use it to set up **personal** agent
preferences so Cursor, Claude Code, Gemini, Antigravity, and Firebender work
the way you work — without overriding the repo harness that already exists.

**Repo files win.** `AGENTS.md`, repo skills, repo hooks, and repo rules are
the team contract for that codebase. Personal config fills gaps (how you like
answers, which local tools you use, cost habits). If a personal rule and a
repo file disagree, follow the repo file.

---

## 1. Precedence — read this first

Agents load more than one instruction source. Treat them as a stack:

| Priority | Source | What it is for |
|----------|--------|----------------|
| 1 | **This chat turn** | The request you typed. Overrides instruction files for that turn. |
| 2 | **Repo harness** | `AGENTS.md` (nearest file to the code you are editing wins), `.agents/skills/`, repo hooks, repo `.cursor/rules/`, repo `.firebender/rules/`, `.claude/settings.json` |
| 3 | **Thin tool adapters in the repo** | `CLAUDE.md` → `AGENTS.md`, `.gemini/settings.json`, optional `GEMINI.md` for Gemini-only overrides |
| 4 | **Personal / machine-local** | `~/.agents/instructions/shared.md` (canonical); thin wrappers in `~/.cursor/rules/`, `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.firebender/rules/` |
| 5 | **Model defaults** | What the product does with no extra files |

**Conflict rule (from [agents.md](https://agents.md/)):** the closest
`AGENTS.md` to the edited file wins; the explicit user prompt overrides
everything.

**What this means in practice**

- Do **not** copy branch-name rules, commit flags, package managers, or
  generate-client commands into personal files. Those belong in the repo.
- Do **not** write a personal rule that says “never `--no-verify`” or
  “always `--no-verify`.” Some Nuuly repos require `--no-verify` for a known
  hook problem; others forbid skipping hooks for new lint failures. Follow
  that repo’s `AGENTS.md` and commit policy.
- Do **not** re-author a repo skill as a personal skill with the same name.
  Repo `.agents/skills/<name>/` is canonical. Personal skills are for tasks
  that are yours, not the team’s.
- Repo **hooks** and deny/ask lists stop a tool mid-turn. Markdown (including
  this guide and `AGENTS.md`) only advises. A personal rule cannot disable a
  repo hook.

---

## 2. What the repo already gives you

Most frontend and services repos already ship a harness. Learn it before you
add personal files.

### Instruction file: `AGENTS.md`

This is the cross-tool briefing document. Cursor, Android Studio Gemini, and
Antigravity read it natively. Claude Code loads it through a `CLAUDE.md`
symlink or `@AGENTS.md` import. Gemini CLI is pointed at it with
`.gemini/settings.json`:

```json
{ "context": { "fileName": ["AGENTS.md"] } }
```

In a monorepo, nested `AGENTS.md` files hold scope-specific rules (CX vs RMS,
an application folder). The root file is often a short router. Do not
duplicate the same engineering rule in `CLAUDE.md` and `GEMINI.md`.

**Antigravity exception:** if both `GEMINI.md` and `AGENTS.md` exist in the
same directory, Antigravity gives `GEMINI.md` the conflict. Keep shared rules
in `AGENTS.md`. Put only Antigravity-specific overrides in `GEMINI.md`.

### Skills: `.agents/skills/<name>/SKILL.md`

Provider-neutral skills live here once. Cursor and Gemini CLI discover
`.agents/skills/` natively. Claude Code discovers `.claude/skills/` — repos
usually expose the same tree with a directory symlink or a session-start
hook. Do not create a second real copy under `.cursor/skills/` for a skill
that already lives in `.agents/skills/`.

Use `/nuuly-create-skill` (in `r15-tech-skills`) when you need a **new**
skill. Decide first: repo skill (team, checked in) vs personal skill (your
machine only).

### Hooks and permissions (the stop, not the advice)

| Product | Mid-turn stop lives here |
|---------|--------------------------|
| Cursor | `.cursor/hooks.json` (set `failClosed` if the repo already does) |
| Claude Code | `.claude/settings.json` deny / ask / allow; optional PreToolUse hooks |
| Gemini CLI | CLI sandbox + approvals (not a repo markdown file) |
| Android Studio Gemini | Agent Permissions and Agent Shell Sandbox **in the IDE** |
| Antigravity | `hooks.json` under `.agents/` or `~/.gemini/config/` |
| Firebender | `.firebender/hooks.json` |

`AGENTS.md` will not return deny. If the repo already asks on `git push` or
denies edits to generated clients, your personal “confirm before push” rule
is extra advice, not a replacement.

Worked example of Goal / Ran / Doubt in PRs on Cloud: section 7 and
[pr-author-packet-rule.md](pr-author-packet-rule.md).

---

## 3. What each tool loads

Use this table when you decide where to put a preference.

| Product | Repo instructions | Repo skills | Personal instructions | Personal rules also load? | Honest gap |
|---------|-------------------|-------------|----------------------|---------------------------|------------|
| **Cursor** (desktop Agent) | `AGENTS.md`; `.cursor/rules/*.mdc` | `.agents/skills/` (also scans `.cursor/skills/` and `.claude/skills/`) | Wrapper `~/.cursor/rules/personal-instructions.mdc` → `~/.agents/instructions/shared.md`; extra `~/.cursor/rules/*.mdc` are Cursor-only | Yes, merged with project rules. **Precedence:** Team Rules → Project Rules → User Rules | Cloud Agents do **not** load `~/.agents/` or `~/.cursor/rules/` |
| **Cursor Cloud Agents** | Clone’s `AGENTS.md`, `.cursor/rules/`, Team Rules | Clone’s `.agents/skills/` | None from your laptop | No | Copy any must-have pref into the repo or Team Rules |
| **Claude Code** | `CLAUDE.md` (symlink to `AGENTS.md` at the session root) | `.claude/skills/` → usually `.agents/skills/` | `~/.claude/CLAUDE.md` (`@~/.agents/instructions/shared.md`); optional `~/.claude/rules/` | Yes | Loads every file in `~/.claude/rules/` (ignores `alwaysApply: false`). Keep always-on prefs in `shared.md`, not a pile of extra Claude rule files. Chat-only Desktop Projects do not auto-load `~/.claude/rules/` |
| **Gemini CLI** | `AGENTS.md` via `.gemini/settings.json` `context.fileName` | `.agents/skills/` (wins over `.gemini/skills/`) | `~/.gemini/GEMINI.md` | Yes | After edits, run `/memory refresh`. `/memory show` lists what loaded. **Product note:** Google docs now describe Antigravity CLI as the successor to Gemini CLI (2026). Verify which CLI your team uses before relying on Gemini-only paths. |
| **Android Studio Gemini** | `AGENTS.md` in the project tree; `.aiexclude` for exclusions | Not the same as Gemini CLI | IDE Agent Permissions | Do not assume `~/.gemini/` or `~/.cursor/rules/` | Not the same product as Gemini CLI. Do not add `.gemini/settings.json` only for Studio. |
| **Antigravity** | `AGENTS.md`; workspace `.agents/rules/`; `GEMINI.md` wins on conflict | Follow product docs; prefer repo `.agents/skills/` | `~/.gemini/GEMINI.md` | Global file is shared with Gemini CLI | No `~/.cursor/rules` bridge. Keep `GEMINI.md` as overrides only. |
| **Firebender** (Android Studio) | `.firebender/rules/*.mdc`; also `.cursor/rules/*.mdc` unless `useCursorRules: false` | Prefer repo `AGENTS.md` / `.agents/skills/` | `~/.firebender/rules/*.mdc` | Yes; merged with project rules | Treat Firebender as the editor-precision role. Claude Code still owns long campaigns. `.mdc` rules advise; hooks stop. |

**Android pairing:** Firebender ≈ Cursor’s job (inline, visual, local).
Claude Code CLI in a terminal with `cwd` = the Android repo owns plan,
multi-file work, and empty-context review. Git is the handoff: one tool
edits at a time. See your team's Claude + Cursor pairing notes if you have them.

---

## 4. Personal settings — what they are and why you want them

Personal files live in your home directory. They apply across repos **on this
machine**. They do not commit with the application repo.

Put here:

- How you want answers written (length, tradeoffs first, no trailing recap).
- Confirm-before-push / never-force-push-to-`main` **if** the repo hook does
  not already cover it.
- Prefer `gh` and `acli` over fetching GitHub or Jira in a browser.
- Cost habits: short sessions, clear between unrelated tasks, cheaper model
  for mechanical work.
- Your username prefix for branches **as a reminder** — still obey that
  repo’s `CONTRIBUTING.md` (services-customer no-ticket names are hyphen-only).
- Personal skills for tasks you repeat and the team does not own.

Do **not** put here:

- How to build, test, or generate clients in a specific repo.
- A second copy of a repo skill.
- A rule that disables a repo hook or ignore file.
- Secrets, tokens, or internal URLs that should not sit in a git-synced
  personal-dotfiles repo without review.

**Why bother?** You stop re-explaining “be short” and “only commit when I
ask” in every chat. The repo still teaches the agent the codebase.

---

## 5. Keep context lean

Vendor docs and context-engineering guides agree on the same constraints.
Personal and repo instruction files compete for the same context window.

**Per file**

- Keep each rule or skill body under **~500 lines**. Split large content into
  `references/` files and link from the main file.
- Write concrete instructions, not vague goals. Point to canonical files in the
  repo instead of copying code into rules.

**Always-on vs scoped**

- Use `alwaysApply: true` only for prefs that must load every session
  (precedence, writing style, commit-when-asked).
- Use `alwaysApply: false` with a clear `description` (Cursor) or path scoping
  (`.claude/rules/` `paths:` field) for situational rules: PR workflows, HTML
  report generation after eval runs, review-before-commit gates.
- Use **skills** (`SKILL.md` in `.agents/skills/`) for multi-step workflows
  the agent loads on demand. See the [Agent Skills
  specification](https://agentskills.io/specification).

**Cumulative load**

- Several short always-on rules still add up. Keep always-on prefs in
  `~/.agents/instructions/shared.md`. Audit extra `~/.cursor/rules/` and
  `~/.claude/rules/` files periodically. If Claude feels heavy, remember Claude
  loads **every** file in `~/.claude/rules/` and ignores `alwaysApply: false` —
  do not dump Cursor-only extras into Claude (see section 8).

**Primacy**

- Put the most important constraints near the **top** of root instruction
  files. Models recall start and end of context better than the middle.

---

## 6. `~/.agents/` — one personal file, several wrappers

Not every engineer uses Cursor. Personal prefs still need **one** file you
edit, and thin wrappers so each product loads that file.

### Layout

```text
~/.agents/
├── .gitignore                # Lab A: copy from templates/agents.gitignore
├── instructions/shared.md    # THE source of truth — edit here
├── rules/creating-pull-requests.mdc  # Goal / Ran / Doubt (symlink in ~/.cursor/rules/)
├── skills/<name>/            # optional personal skills (section 11)
└── README.md                 # optional reinstall notes
```

This is **personal** content. It is not a replacement for repo `AGENTS.md` or
repo `.agents/skills/`.

### Version it (personal git repo)

Treat `~/.agents/` as a reinstallable dotfiles tree on this machine.

```bash
mkdir -p ~/.agents
git -C ~/.agents init
cp templates/agents.gitignore ~/.agents/.gitignore
```

Use a **private** remote if you add one. Never commit tokens, `.env`, or keys.
Do not push this tree to a public GitHub repo. Do not treat it as the team
harness. Wrappers under `~/.claude/` and `~/.cursor/` stay outside this git
tree unless you add them on purpose.

The script [`lab/wire-personal-agents.sh`](lab/wire-personal-agents.sh) writes
the wrappers:

| Product | Wrapper | How it follows `shared.md` |
|---------|---------|----------------------------|
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/instructions/shared.md` (live after body edits) |
| Cursor | `~/.cursor/rules/personal-instructions.mdc` | `alwaysApply: true` plus an **embedded copy** (re-run wire after edits) |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` | **Embedded copy** (re-run wire after edits) |
| Firebender | `~/.firebender/rules/personal-instructions.mdc` | Frontmatter plus an **embedded copy** (re-run wire after edits) |

### Commands

You can run the two `bash` lines in Terminal, **or** paste this into a local
agent that can run a shell (Cursor Agent on this Mac, Claude Code, Gemini
CLI, Antigravity). Do **not** ask a Cursor Cloud Agent. Firebender: use that
chat only if it can run a terminal command; otherwise Studio Terminal.

```
Run these two commands from the ai-workshops clone root.
Do not commit or push. Paste the --check output.
If a wrapper conflicts, stop and show me the message.

bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh
bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh --check
```

```bash
mkdir -p ~/.agents/instructions ~/.agents/rules ~/.cursor/rules
cp templates/shared.md ~/.agents/instructions/shared.md
cp templates/creating-pull-requests.mdc ~/.agents/rules/creating-pull-requests.mdc
ln -sfn ~/.agents/rules/creating-pull-requests.mdc ~/.cursor/rules/creating-pull-requests.mdc
# Edit shared.md. Keep the Precedence block.

# Lab A step 4 — required
cp templates/agents.gitignore ~/.agents/.gitignore
git -C ~/.agents init

# Lab B — from clone root (folder that contains workshops/)
bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh
bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh --check

# Only the products you use:
bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh --tools=claude,gemini
```

Optional alias (only if you want a short name; not required):

```bash
alias wire-personal-agents='bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh'
```

Run that alias from the clone root.

### When to run

- After Lab A, once `shared.md` exists
- After you edit `shared.md` if you use Cursor, Gemini, or Firebender
- After cloning the lab folder on a new machine

You do **not** need to re-run after editing `shared.md` for Claude (it
`@`-imports the file). Cursor, Gemini, and Firebender embeds are stale until
you re-run.

### What the script does **not** do

- Does **not** replace repo `AGENTS.md`, repo skills, or repo hooks
- Does **not** overwrite an unmanaged `GEMINI.md`, Cursor wrapper, or Claude
  `CLAUDE.md` (reports a conflict)
- Does **not** load on Cursor Cloud Agents (section 7)

### Verify

1. `bash wire-personal-agents.sh --check` prints `Personal agents wire: ok`
2. New Claude session: `/memory` or `/context` lists personal `CLAUDE.md`
3. New Cursor Agent chat: distinctive line from `shared.md` appears
4. Gemini: `/memory refresh` then `/memory show` lists `GEMINI.md`
5. Firebender: new chat quotes the Precedence line

Full how-to: [lab/README.md](lab/README.md).

### Optional: extra Cursor-only `.mdc` files

If you already keep situational Cursor rules under `~/.cursor/rules/*.mdc`
that should **not** live in `shared.md`, you can still mirror those extras
into Claude with [`lab/sync-personal-rules.sh`](lab/sync-personal-rules.sh)
and `~/.cursor/rules/.claude-exclude`. That is not the workshop default.

---

## 7. Cursor Cloud Agents — promote prefs to the repo (or team)

**Recommended practice (Cursor docs):** Cloud Agents run on a remote VM that
clones the repo. They do **not** load your laptop’s personal rules. Anything
that must apply on Cloud belongs in the **repo harness** or **Team Rules** —
not in `~/.agents/` or `~/.cursor/rules/`.

This is not a workaround for a bug. Desktop Agent and Cloud Agent are different
runtimes. Personal files stay personal; team contracts stay in git.

### What Cloud Agents load

| Source | Loads on Cloud? | Notes |
|--------|-----------------|-------|
| `AGENTS.md` (root and nested) | Yes | [Cursor recommends](https://cursor.com/docs/cloud-agent/setup) a **Cursor Cloud specific instructions** section for Cloud-only setup and testing |
| Repo `.cursor/rules/*.mdc` | Yes | Same as local project rules |
| Repo `.agents/skills/` | Yes | Checked in with the clone |
| Repo `.cursor/hooks.json` | Yes | After the agent has a writable environment |
| **Team Rules** (dashboard) | Yes | Team / Enterprise; precedence over project and user rules on desktop too |
| `~/.agents/instructions/shared.md` | **No** | Personal file on your machine |
| `~/.cursor/rules/` | **No** | Personal file rules on your machine |
| Cursor **Settings → User Rules** | **No** | Stored in your Cursor account for desktop Agent, not copied to the Cloud VM |
| `~/.cursor/hooks.json` | **No** | User-level hooks are machine-local |
| `wire-personal-agents.sh` wrappers | **No** | Home-directory files; Cloud never saw your laptop |

### Optional: personal skills on Cloud

Cursor can **Sync Skills for Cloud Agents** (Settings → Agents) to copy
`~/.cursor/skills/` to **your** Cloud runs. That is for **personal skills**,
not personal rules. Repo skills in `.agents/skills/` already travel with the
clone and are the team default. Do not treat skill sync as a substitute for
checking in shared workflows.

### What to promote (and where)

Copy **team** requirements into the repo or Team Rules. Keep **individual**
habits (writing style, cost prefs) personal unless the whole team adopts them.

| If this must apply on Cloud… | Put it here |
|------------------------------|-------------|
| PR body format (Goal / Ran / Doubt) | Repo `.cursor/rules/` rule, `AGENTS.md` section, `.github/pull_request_template.md`, or Team Rules — see [pr-author-packet-rule.md](pr-author-packet-rule.md) |
| Commit / push policy for agents | Repo `AGENTS.md` + hooks (hooks enforce; markdown advises) |
| Build, test, generate-client commands | Repo `AGENTS.md` (never personal rules) |
| Org-wide convention across many repos | Team Rules + optional team marketplace plugins |
| Cloud-only install / test steps | `AGENTS.md` section titled e.g. `Cursor Cloud specific instructions` |

**Do not** symlink `~/.agents/` or `~/.cursor/rules/` into a repo or commit a
copy of your personal rule set unless the team explicitly wants those exact
prefs.

### Quick check

Before relying on Cloud for a task, ask: “Is this instruction in the clone?”
If no, add it to the repo or Team Rules before starting the Cloud run.

---

## 8. Per-product wrappers and verify

Section 6 is the default. This section is the three-step verify for each
product, plus personal-skill symlinks.

### Claude Code

1. **File check:** `~/.claude/CLAUDE.md` contains
   `@~/.agents/instructions/shared.md` (`wire-personal-agents.sh --check`).
2. **Product lists files:** New session; `/memory` or `/context`.
3. **Smoke test:** Section 13 prompts.

### Cursor

1. **File check:** `~/.cursor/rules/personal-instructions.mdc` exists.
2. **Product lists files:** New Agent chat; quote the Precedence line from
   personal prefs. Do not put the file path in the prompt.
3. **Smoke test:** Section 13 prompts.

Cursor Cloud Agents do not load these wrappers (section 7).

### Gemini CLI and Antigravity

Both use `~/.gemini/GEMINI.md`. The wire script embeds `shared.md` so
`/memory show` has the text.

1. **File check:** `~/.gemini/GEMINI.md` includes the Precedence line.
2. **Product lists files:** `/memory refresh`, then `/memory show`. Confirm
   `GEMINI.md` and repo `AGENTS.md`.
3. **Smoke test:** Section 13 prompts.

Android Studio Gemini is not Gemini CLI. Do not use `/memory show` for Studio.

### Firebender

1. **File check:** `ls -l ~/.firebender/rules/*.mdc` — wrapper exists.
2. **Product lists files:** New Firebender chat; quote the Precedence line.
3. **Smoke test:** Section 13 prompts.

Project `.cursor/rules/` in the repo is not the personal wrapper. Do not
symlink Cursor-only Cloud workarounds into Firebender.

### Personal skills (optional)

Author under `~/.agents/skills/<name>/`, then symlink discovery dirs if the
product does not scan `~/.agents/skills/` itself:

```bash
ln -sfn ~/.agents/skills/<name> ~/.cursor/skills/<name>
ln -sfn ~/.agents/skills/<name> ~/.claude/skills/<name>
```

Never create a **real** directory at `~/.cursor/skills/<name>` or
`~/.claude/skills/<name>` that duplicates a repo skill of the same name.

---

## 9. Highest-leverage personal prefs

Steal these. Keep them short. Drop any line that fights a repo file.

**Communication**

- Be short. No preamble. No recap of the diff I can already read.
- State each finding once.
- Name a real tradeoff in 1–2 sentences and let me decide.

**Permissions and friction**

- Do not ask permission for read-only work (`git status`, `git log`,
  `gh pr view`, `acli` reads).
- Confirm before push, opening or closing a PR, deleting a branch,
  force-push, or anything other people will see — unless a repo hook
  already asks or denies.
- Allow-list read-only CLI subcommands in the **product** settings
  (Claude permissions, Cursor auto-run). Leave mutating commands off the
  list so they prompt.

**Safety (personal, not a substitute for hooks)**

- Only commit or open a PR when I explicitly ask. A commit request is not
  permission to push.
- Never force-push to `main` or `master`.
- Follow the **open repo’s** commit-hook and branch-name rules. Do not
  invent a global `--no-verify` policy.

**Tool routing**

- Prefer `gh` for GitHub and `acli` for Jira/Confluence over fetching those
  sites in a browser.
- Prefer the repo’s context-efficiency or symbol-search skill when it
  exists, instead of dumping directories into chat.

**Code habits**

- Prefer editing existing files. Do not add READMEs or planning docs unless
  asked.
- No code comments unless the *why* is non-obvious.

**Cost and context**

- The main thread plans and decomposes. Do **not** explore in the main loop.
- Spike unknowns (API probing, huge-file reads) in a subagent or a second
  session when the product supports it. Return a short finding.
- One focused chat per task. New Cursor chat or Claude `/clear` between
  unrelated work.
- Use a cheaper / faster model for scaffolding and lint loops; keep the
  expensive model for design and hard review.
- Several short sessions cost less than one session that re-bills a huge
  context on every turn.

**Defaults for ambiguity**

- If I do not specify a time range, ask. Do not assume “last 30 days.”

---

## 10. Example personal instruction file

Save this as `~/.agents/instructions/shared.md`. Adapt it. Do not paste it as
a second `AGENTS.md`. The first block is required.

```markdown
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
- The main thread plans. Do not explore in the main loop.
- Spike unknowns in a subagent or a second session. Return a short finding.
- New chat or `/clear` at phase boundaries.
- Cheaper model for mechanical work.

## Defaults
- Commits and PRs only when I ask. Push only when I say push.
- Prefer edit over new files. No unsolicited READMEs.
- Comments in code only when the why is non-obvious.
- Branch names: follow this repo’s CONTRIBUTING / AGENTS.md. If the name
  is wrong, stop and ask; do not rename the branch on GitHub.
```

Claude-specific extras (subagent roster, `/memory`, sandbox notes) belong
in `~/.claude/CLAUDE.md` **outside** the managed wire region, not in
`shared.md` (that file is also fed to Cursor, Gemini, and Firebender).

---

## 11. Personal skills

A **skill** is a named recipe: instructions plus optional scripts. Global
prefs say how you work. A skill says how to do **one** job the same way
every time.

Skills follow the open [Agent Skills
specification](https://agentskills.io/specification): a directory with
`SKILL.md` (YAML frontmatter + markdown body), optional `scripts/`,
`references/`, and `assets/`. Cursor, Claude Code, Gemini CLI, and Copilot
discover `.agents/skills/` in the repo; personal skills live under
`~/.agents/skills/` or tool-specific home dirs (section 8).

**Repo skill first.** If the job is “create a PR in this application repo,”
“run the iOS VQA check,” or “archive a Jira ticket,” use the skill in
`.agents/skills/`. Do not fork it into `~/.agents/skills/`.

**Personal skill** when you keep re-explaining a step-by-step that is yours:
open a file in the right app, spin up your preferred worktree layout, wrap
up session memory into `~/.ai-memory/`. A finished sample of the worktree
layout is [example/home-agents/skills/create-worktree/](example/home-agents/skills/create-worktree/).

### Write the spec before you invoke the authoring skill

Before `/nuuly-create-skill`, write a short note:

- The problem and what you do by hand today
- Trigger phrases
- Inputs and outputs
- Step-by-step, including what it must **not** do
- Which steps are a script vs judgment

Hand that note to the skill. A vague request yields a skill that misfires.

`nuuly-create-skill` works in Cursor, Claude Code, and Claude Desktop. It
writes the standard `.agents/skills/<name>/` layout and will steer you to a
script or runbook when a skill is the wrong fit.

### Design lesson

Put the deterministic part in a script. The agent only decides *which*
inputs to pass. That is cheaper and more predictable than re-reasoning the
routing every time.

---

## 12. Subagents — use them where the product has them

A **subagent** is a separate agent with its own context. It returns a
summary. The main thread does not keep every file read.

| Product | What exists today | Practical advice |
|---------|-------------------|------------------|
| Claude Code | Custom agents in `~/.claude/agents/` or `~/.agents/agents/`; Task-style spawn | A standing routing table in personal instructions is more reliable than `description` auto-pick. Name the agent when it matters (`@code-reviewer`). |
| Cursor | Task / subagent tool in Agent chat; Cloud Agents are a different runtime | Use a subagent for research or a second-model review. Do not assume Claude’s YAML agent files load in Cursor. |
| Gemini CLI | Extensions and skills; not the same Claude agent YAML | Delegate with a second session or a skill, not a copied `~/.claude/agents/` file. |
| Antigravity | Workflows and hooks; check current product docs | Do not port Claude agent frontmatter and expect it to run. |
| Firebender | Studio-local agents; hooks in `.firebender/hooks.json` | Keep Firebender on small local edits. Hand long work to Claude Code. |

**Skill vs subagent**

- A skill is a recipe (“here is how”).
- A subagent is a worker (“here is who,” with its own context).
- A skill can tell the main thread to spawn a worker. A worker can load a
  skill. If you would hand the task to a teammate, consider a subagent
  **in a product that supports one**.

**Do not start from a nine-agent language-writer roster.** That is one
person’s Claude setup. Start with one read-only reviewer and one “summarize
this long doc” worker if you actually use Claude Code that way. Add more
only when you keep doing the same handoff.

If you do define Claude agents, put a **routing table** in personal
instructions and write sharp `description` fields (“Use PROACTIVELY for… /
NOT for…”). Auto-routing from description alone is inconsistent.

---

## 13. Getting started

1. Open the application repo you use most. Read root `AGENTS.md` (and the
   nested file for your domain). Note hooks and `.agents/skills/`.
2. Write five to ten **personal** lines that do not repeat that file
   (section 10).
3. Save them as `~/.agents/instructions/shared.md`. Keep the Precedence block
   at the top. Keep the three writing lines (no preamble, no trailing summary,
   state each finding once).
4. `git -C ~/.agents init` if you have not. Copy `lab/templates/agents.gitignore`
   to `~/.agents/.gitignore`. Private remote only; no secrets.
5. From the workshop `lab/` folder, run `bash wire-personal-agents.sh` then
   `--check` (section 6). Use `--tools=` if you only use some products.
6. Claude: new session; `/memory` or `/context` lists personal `CLAUDE.md`.
7. Gemini CLI / Antigravity: `/memory refresh`, then `/memory show` (section 8).
8. Firebender: `ls -l ~/.firebender/rules/*.mdc`, then a quote test (section 8).
9. Cursor: new Agent chat; quote the Precedence line from `shared.md`.
10. Smoke test in **each** product you verified: same prompt twice — draft a PR
    body, do not open or push. First in an app repo with no PR headings
    (expect Goal / Ran / Doubt). Then with this clone open (expect What /
    Why this repo / Verify).
11. Lab D in the **application** repo: paste [lab/lab-d-prompt.md](lab/lab-d-prompt.md).
    Cursor / Claude should spawn a Task or subagent. Gemini CLI: second session.
12. Add a personal skill only after you have written the spec (section 11).
13. If you use **Cursor Cloud Agents**, promote must-have prefs into the repo
    or Team Rules (section 7). See [pr-author-packet-rule.md](pr-author-packet-rule.md)
    for the PR example.

---

## Related

### Workshop docs

| Doc | What it is |
|-----|------------|
| [lab/README.md](lab/README.md) | Participant setup: templates, wire script, verify steps |
| [slides.html](slides.html) | Live 17-slide deck (no speaker notes) |
| [customizing-your-agent-workflow-slides-draft-3.html](customizing-your-agent-workflow-slides-draft-3.html) | Same deck with speaker notes (facilitator) |
| [example/](example/) | Sample finished personal setup (`~/.agents/` + wrappers); [walkthrough](example/walkthrough.md) |
| [lab/wire-personal-agents.sh](lab/wire-personal-agents.sh) | Point Claude, Cursor, Gemini, Firebender at `~/.agents/instructions/shared.md` |
| [lab/sync-personal-rules.sh](lab/sync-personal-rules.sh) | Optional: extra Cursor `.mdc` files → Claude |
| [handout-laptop-vs-repo-adapters.md](handout-laptop-vs-repo-adapters.md) | Why the laptop wire script is allowed and a repo SessionStart wrapper script is not |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Goal / Ran / Doubt PRs; Cursor Cloud promotion example |

### Vendor and open standards

| Doc | What it is |
|-----|------------|
| [agents.md](https://agents.md/) | Cross-tool `AGENTS.md` standard; nearest file wins |
| [Cursor Rules](https://cursor.com/docs/rules) | `.cursor/rules/*.mdc`, `AGENTS.md`, best practices |
| [Cursor Cloud Agent setup](https://cursor.com/docs/cloud-agent/setup) | Environments; `AGENTS.md` Cloud section |
| [Claude Code — Features overview](https://code.claude.com/docs/en/features-overview) | When to use `CLAUDE.md`, skills, hooks, subagents |
| [Agent Skills specification](https://agentskills.io/specification) | Portable `SKILL.md` format |
| [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Why lean, specific instructions beat long prompts |
| [Claude Code memory](https://code.claude.com/docs/en/claude-md) | `CLAUDE.md` symlink / `@AGENTS.md` |
| [Android Studio agent files](https://developer.android.com/studio/gemini/agent-files) | Studio Gemini reads `AGENTS.md` |
| [Gemini CLI context](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) | `context.fileName` |
| [Antigravity rules](https://antigravity.google/docs/ide/rules/) | Global `~/.gemini/GEMINI.md`; workspace `.agents/rules/` |
| [Firebender rules](https://docs.firebender.com/api-reference/rules) | `.firebender/rules/` and `~/.firebender/rules/` |
