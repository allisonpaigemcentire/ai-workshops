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
| 4 | **Personal / machine-local** | `~/.cursor/rules/`, `~/.claude/`, `~/.gemini/GEMINI.md`, `~/.firebender/rules/` |
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
| **Cursor** (desktop Agent) | `AGENTS.md`; `.cursor/rules/*.mdc` | `.agents/skills/` (also scans `.cursor/skills/` and `.claude/skills/`) | `~/.cursor/rules/*.mdc` | Yes, merged with project rules. **Precedence:** Team Rules → Project Rules → User Rules | Cloud Agents do **not** load `~/.cursor/rules/` |
| **Cursor Cloud Agents** | Clone’s `AGENTS.md`, `.cursor/rules/`, Team Rules | Clone’s `.agents/skills/` | None from your laptop | No | Copy any must-have pref into the repo or Team Rules |
| **Claude Code** | `CLAUDE.md` (symlink to `AGENTS.md` at the session root) | `.claude/skills/` → usually `.agents/skills/` | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | Yes | Loads every file in `~/.claude/rules/` (ignores `alwaysApply: false`). List Cursor-only stems in `~/.cursor/rules/.claude-exclude`. Chat-only Desktop Projects do not auto-load `~/.claude/rules/` |
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

- Several short always-on rules still add up. Audit `~/.cursor/rules/` and
  `~/.claude/rules/` periodically. If Claude feels heavy, remember Claude loads
  **every** file in `~/.claude/rules/` and ignores `alwaysApply: false` — use
  `.claude-exclude` for Cursor-only rules (see section 6).

**Primacy**

- Put the most important constraints near the **top** of root instruction
  files. Models recall start and end of context better than the middle.

---

## 6. `sync-personal-rules.sh` — Cursor ↔ Claude bridge

Cursor and Claude Code read different home-directory folders. Without a bridge,
you maintain two copies of the same personal prefs and they drift.

The script [`lab/sync-personal-rules.sh`](lab/sync-personal-rules.sh) in this
workshop folder (or your local copy of it) keeps **one canonical source** and
mirrors it into Claude.

### What it does

| Path | Role |
|------|------|
| `~/.cursor/rules/*.mdc` | **Canonical** — edit personal rules here |
| `~/.claude/rules/<stem>.md` | Symlink → each mirrored `.mdc` |
| `~/.claude/CLAUDE.md` | Managed index (Precedence section + rule table) when missing or already managed by the script |
| `~/.cursor/rules/.claude-exclude` | Stems **not** mirrored (Cursor-only rules) |

**Phase 1:** Remove broken symlinks and links for excluded stems.  
**Phase 2:** For each `*.mdc` in `~/.cursor/rules/`, create or fix a symlink
in `~/.claude/rules/` unless the stem is in `.claude-exclude`.  
**Phase 3:** Write or refresh managed `~/.claude/CLAUDE.md` with a Precedence
block and a table of linked rules.

Symlink **content** stays live when you edit an existing `.mdc`. **Adding or
removing** a rule file requires another sync run.

### Commands

From the workshop `lab/` directory that contains the script:

```bash
# Create or update symlinks and managed CLAUDE.md
bash sync-personal-rules.sh

# Report drift; exit 1 if out of sync (use in CI or a pre-flight check)
bash sync-personal-rules.sh --check

bash sync-personal-rules.sh --help
```

Optional shell alias:

```bash
alias sync-personal-rules='bash ~/path/to/ai-workshops/workshops/customizing-agent-workflow/lab/sync-personal-rules.sh'
```

### When to run

- After you **add**, **rename**, or **remove** a file in `~/.cursor/rules/`
- After you edit `.claude-exclude`
- After cloning this workshop's `lab/` folder on a new machine, once personal rules exist on disk

You do **not** need to re-run after editing the **body** of an existing `.mdc`
(the symlink picks up changes immediately).

### `.claude-exclude`

Claude Code loads every file in `~/.claude/rules/` at session start and does
**not** honor Cursor’s `alwaysApply: false`. Put Cursor-only or situational
stems in `.claude-exclude` (one stem per line, `#` comments allowed). For
excluded PR/commit rules, the managed `~/.claude/CLAUDE.md` carries a short
summary; Claude should read the full `~/.cursor/rules/<stem>.mdc` when that
work starts.

```text
# Cursor-only — keyword trigger, IDE deliverable, or situational (read on demand)
sean-review-keyword
context-baseline-html-report
creating-pull-requests
cody-review-before-commit
```

Re-run sync after editing the exclude file so stale symlinks are removed.

### What the script does **not** do

- Does **not** sync to Gemini CLI, Antigravity, or Firebender — copy the same
  prefs into `~/.gemini/GEMINI.md` and `~/.firebender/rules/` separately
  (section 8).
- Does **not** overwrite a real file at `~/.claude/rules/<stem>.md` that is
  not a symlink (reports a conflict and leaves it alone).
- Does **not** replace repo `AGENTS.md`, repo skills, or repo hooks.

### Verify

1. Run `bash sync-personal-rules.sh --check` from the workshop `lab/` folder — should print
   `Personal rules bridge: ok (N Cursor rule(s))`.
2. Start a new Claude Code session. Run `/memory` or `/context` and confirm
   mirrored rules appear.
3. In Cursor, start a new Agent chat — Cursor reads `~/.cursor/rules/` directly.

Full how-to: [lab/README.md](lab/README.md) (participant setup steps).

---

## 7. Cursor Cloud Agents — promote prefs to the repo (or team)

**Recommended practice (Cursor docs):** Cloud Agents run on a remote VM that
clones the repo. They do **not** load your laptop’s personal rules. Anything
that must apply on Cloud belongs in the **repo harness** or **Team Rules** —
not in `~/.cursor/rules/`.

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
| `~/.cursor/rules/` | **No** | Personal file rules on your machine |
| Cursor **Settings → User Rules** | **No** | Stored in your Cursor account for desktop Agent, not copied to the Cloud VM |
| `~/.cursor/hooks.json` | **No** | User-level hooks are machine-local |
| `sync-personal-rules.sh` output | **No** | Claude bridge only; Cloud never saw your home directory |

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

**Do not** symlink `~/.cursor/rules/` into a repo or commit a copy of your
personal rule set unless the team explicitly wants those exact prefs.

### Quick check

Before relying on Cloud for a task, ask: “Is this instruction in the clone?”
If no, add it to the repo or Team Rules before starting the Cloud run.

---

## 8. One personal source, several tool pointers

Each product has its own home-directory folder. If you paste the same
paragraph into three files, they drift.

### Recommended Nuuly pattern (Cursor + Claude)

Keep editable personal rules in `~/.cursor/rules/*.mdc`. Use `alwaysApply:
true` only for prefs that must load every session (section 5). Mirror into
Claude with **section 6** (`sync-personal-rules.sh`).

- Cursor frontmatter (`alwaysApply`, `globs`, `description`) is ignored by
  Claude; the markdown body is what Claude uses.
- Details: [lab/README.md](lab/README.md).

### Gemini CLI and Antigravity

Add the **same personal prefs** (not repo engineering rules) to
`~/.gemini/GEMINI.md`. Both Gemini CLI and Antigravity global rules use that
file. Start the file with:

```markdown
# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict.
```

In Gemini CLI, run `/memory refresh` after edits.

#### Verify (Gemini CLI and Antigravity)

1. **File check:** `~/.gemini/GEMINI.md` exists and starts with the Precedence
   line (or the opener above).
2. **Product lists files:** In an active Gemini CLI session, run
   `/memory refresh`, then `/memory show`. Confirm `GEMINI.md` and repo
   `AGENTS.md` appear in the list.
3. **New session smoke test:** Use the two prompts from section 13 (getting
   started): draft a PR body, then ask what `AGENTS.md` says about commits.
   Confirm the **repo** rule wins when it conflicts with a personal habit.

Antigravity global rules use the same `~/.gemini/GEMINI.md`. Android Studio
Gemini is not Gemini CLI — do not use `/memory show` to verify Studio.

### Firebender

Put the same prefs in `~/.firebender/rules/personal.mdc` with
`alwaysApply: true`. Firebender can also read `.cursor/rules/` **in the
project**. It does not automatically read `~/.cursor/rules/` unless you
symlink:

```bash
mkdir -p ~/.firebender/rules
ln -sfn ~/.cursor/rules/plain-writing.mdc ~/.firebender/rules/plain-writing.mdc
```

Only symlink files that are safe and useful in Android Studio. Do not
symlink a Cursor-only Cloud Agents workaround into Firebender.

Project `.cursor/rules/` in the repo is not `~/.cursor/rules/`. Personal
Cursor rules reach Firebender only via `~/.firebender/rules/` (copy or
symlink).

#### Verify (Firebender)

1. **File check:** `ls -l ~/.firebender/rules/*.mdc` — each entry is a real
   file or a symlink into `~/.cursor/rules/` (Firebender documents symlink
   support).
2. **Product lists files:** Firebender has no documented `/memory show`. In a
   **new** Firebender chat, ask it to name the personal rule files under
   `~/.firebender/rules` and quote the Precedence line from your personal
   rule. Do not invent a CLI flag.
3. **New session smoke test:** Same two prompts as Gemini (section 13): draft
   a PR body, then ask what `AGENTS.md` says about commits. Confirm the **repo**
   rule wins.

### Optional `~/.agents/` layout

Some people keep personal skills and a `shared.md` under `~/.agents/` and
point tool wrappers at it. That is fine for **personal** content. It is not
a replacement for the repo’s `.agents/skills/` or `AGENTS.md`.

```text
~/.agents/
├── instructions/shared.md    # personal prefs only
├── skills/<name>/            # personal skills
└── README.md
```

- Claude: `@~/.agents/instructions/shared.md` from `~/.claude/CLAUDE.md`
  **after** the managed personal-rules index, or as a section inside it.
- Cursor: a thin `~/.cursor/rules/personal-instructions.mdc` that restates
  or `@`-imports the same text.
- Skills: author under `~/.agents/skills/<name>/`, then symlink discovery
  dirs if the product does not scan `~/.agents/skills/` itself.

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

- One focused chat per task. New Cursor chat or Claude `/clear` between
  unrelated work.
- Delegate large research or long-file reads to a subagent or a second
  session when the product supports it, so the main thread stays short.
- Use a cheaper / faster model for scaffolding and lint loops; keep the
  expensive model for design and hard review.
- Several short sessions cost less than one session that re-bills a huge
  context on every turn.

**Defaults for ambiguity**

- If I do not specify a time range, ask. Do not assume “last 30 days.”

---

## 10. Example personal instruction file

Adapt this. Do not paste it as a second `AGENTS.md`. The first block is
required.

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
- Delegate long reads and wide search; keep the main thread as the
  orchestrator.
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
in `~/.claude/CLAUDE.md` only, not in a file you also feed to Cursor and
Firebender.

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
up session memory into `~/.ai-memory/`.

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
3. Put them in `~/.cursor/rules/` as `.mdc` with `alwaysApply: true` for
   always-on prefs; use `alwaysApply: false` + `description` for situational
   rules (section 5).
4. Run `bash sync-personal-rules.sh` from the workshop `lab/` folder (section 6) so
   Claude Code sees them. Verify with `--check`, then `/memory` or `/context`
   (section 6 Verify).
5. If you use Gemini CLI or Antigravity: copy the same prefs into
   `~/.gemini/GEMINI.md`, then run the three-step verify in section 8
   (`/memory refresh`, `/memory show`, smoke test).
6. If you use Firebender: add `~/.firebender/rules/` (or symlinks to Cursor
   files that apply), then run the three-step verify in section 8 (`ls -l`,
   quote test in chat, smoke test).
7. In Cursor: start a new Agent chat and confirm your personal lines load
   (section 6 Verify step 3).
8. Smoke test in **each** product you verified: “Draft a PR body for this
   branch” and “What does `AGENTS.md` say about commits?” Confirm the repo
   rule is what the agent follows.
9. Add a personal skill only after you have written the spec (section 11).
10. If you use **Cursor Cloud Agents**, promote must-have prefs into the repo
    or Team Rules (section 7). See [pr-author-packet-rule.md](pr-author-packet-rule.md)
    for the PR example.

---

## Related

### Workshop docs

| Doc | What it is |
|-----|------------|
| [lab/README.md](lab/README.md) | Participant setup: templates, sync script, verify steps |
| [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) | Slide deck for this workshop |
| [lab/sync-personal-rules.sh](lab/sync-personal-rules.sh) | Cursor `~/.cursor/rules` → Claude `~/.claude/rules` sync |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Goal / Ran / Doubt PRs; Cursor Cloud promotion example |
| [lab/verify-checklist.md](lab/verify-checklist.md) | Exit checklist for the 60-minute session |

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
