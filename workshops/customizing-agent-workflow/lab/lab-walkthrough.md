# Lab walkthrough — Customizing Your Agent Workflow

Step-by-step guide for Labs A, B, C, and D. Time boxes match the 60-minute
workshop. Run only the steps for products you actually use.

**Before you start**

1. Open an application repo you use daily. It must already have `AGENTS.md`.
2. Clone this lab folder if you have not:

   ```bash
   git clone https://github.com/allisonpaigemcentire/ai-workshops.git
   cd ai-workshops/workshops/customizing-agent-workflow/lab
   ```

3. Keep [handout.md](../handout.md) open for reference.

---

## Lab A — Write personal prefs (10 minutes)

**Goal:** Create **one** personal instruction file. Keep the Precedence block
and the three writing lines (no preamble, no trailing summary, state each
finding once). Copy `creating-pull-requests.mdc` so Lab C in an app repo with
no PR headings gets Goal / Ran / Doubt the same way Cursor does on a machine
that already has that gate. Copy `agents.gitignore` and `git init` so
`~/.agents/` is a git tree with secrets blocked. Add tool and cost lines
that do not repeat your repo's `AGENTS.md`.

### Step 1 — Copy the starter

From the `lab/` directory:

```bash
mkdir -p ~/.agents/instructions ~/.agents/rules ~/.cursor/rules
cp templates/shared.md ~/.agents/instructions/shared.md
cp templates/creating-pull-requests.mdc ~/.agents/rules/creating-pull-requests.mdc
ln -sfn ~/.agents/rules/creating-pull-requests.mdc ~/.cursor/rules/creating-pull-requests.mdc
```

Do **not** copy `shared.md` into each product's home folder by hand. Lab B
points Claude, Cursor, Gemini, and Firebender at that one file. The
`creating-pull-requests.mdc` symlink is how Cursor loads the full Goal / Ran /
Doubt gate (`alwaysApply: false`, description match). The same headings are
already in `shared.md` so Claude, Gemini, and Firebender see them after Lab B.

### Step 2 — Keep the Precedence block at the top

Your file must start with this block (already in the template):

```markdown
## Precedence

Repo `AGENTS.md`, `.agents/skills/`, repo hooks, and repo rules win.
These lines are personal prefs for this machine. On conflict, follow the repo.
```

### Step 3 — Keep the writing lines; add yours

1. Keep **no preamble**, **no trailing summary of the diff**, and **state each
   finding once**.
2. Keep the orchestrator lines under Context cost, or write the same idea in
   your own words: main thread plans; do not explore in the main loop.
3. Add or edit tool habits. Do **not** copy branch rules, commit flags, package
   managers, or generate-client commands from the repo.
4. Lab B load check is quoting the Precedence line. Do not add “end every reply
   with what happens next.”

### Step 4 — Copy `.gitignore` and `git init`

From the `lab/` directory:

```bash
cp templates/agents.gitignore ~/.agents/.gitignore
git -C ~/.agents init
```

This step is required. The template blocks `.env`, keys, tokens, and secrets
if you later add a private remote. Do not push `~/.agents` to a public GitHub
repo.

### Step 5 — Save

Save only at `~/.agents/instructions/shared.md`.

**Lab A done when:** That file exists and starts with the Precedence block,
`~/.agents/.gitignore` exists, and `git -C ~/.agents status` works.

---

## Lab B — Wire and verify (10 minutes)

**Goal:** For each product you use, run the same three steps:

1. **File check** — canonical file on disk; wrapper points at it.
2. **Product lists files** — the tool shows your personal prefs loaded.
3. **Smoke test** — Lab C (next section).

### All products — run the wire script

The wrappers exist only after `wire-personal-agents.sh` **runs**. You do not
have to type `bash` in Terminal.app. Paste the prompt below into a **local**
agent that can run a shell. Do **not** use a Cursor Cloud Agent.

**Cursor** — Agent chat on this Mac (not Ask, not Cloud). Approve the
terminal command if Cursor asks.

**Claude Code** — paste in the CLI session; approve bash if asked.

**Gemini CLI** — paste in Gemini CLI (not Android Studio Gemini).

**Antigravity** — agent/chat that can run a terminal command. Same two
`bash` lines. Writes `~/.gemini/GEMINI.md`.

**Firebender** — if this chat can run a terminal command, paste the prompt.
If it cannot, run the two `bash` lines in Android Studio **Terminal** or
macOS Terminal.

From the **ai-workshops clone root** (the folder where `ls` shows `AGENTS.md`
and `workshops/`):

```
Run these two commands. Do not commit or push. Paste the --check output.
If a wrapper conflicts, stop and show me the message.

bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh
bash workshops/customizing-agent-workflow/lab/wire-personal-agents.sh --check
```

If you already have this `lab/` folder open, the short form is enough:

```bash
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

**Expected output:** `Personal agents wire: ok (N wrapper(s) → …/shared.md)`

Only the products you use:

```bash
bash wire-personal-agents.sh --tools=claude,cursor
bash wire-personal-agents.sh --check --tools=claude,cursor
```

Valid `--tools` names: `claude`, `cursor`, `gemini`, `firebender`.

Re-run after you edit `shared.md` if you use **Cursor, Gemini, or Firebender**
(those wrappers embed a copy and are stale until you re-run). Claude `@`
import stays live.

Then run only the product sections below that apply to you.

### Cursor

**Step B1 — File check**

```bash
ls ~/.cursor/rules/personal-instructions.mdc
```

Confirm the wrapper exists and mentions `~/.agents/instructions/shared.md`.

**Step B2 — Product lists files**

1. Open your application repo in Cursor.
2. Start a **new** Agent chat.
3. Ask: `Quote the Precedence line from my personal prefs`

**Step B3 — Smoke test**

Continue to Lab C below.

**Note:** Cursor Cloud Agents do **not** load `~/.agents/` or
`~/.cursor/rules/` from your laptop. If you use Cloud, promote must-have
prefs into the repo or Team Rules (handout section 7).

---

### Claude Code

**Step B1 — File check**

Wire `--check` already confirmed `~/.claude/CLAUDE.md` contains
`@~/.agents/instructions/shared.md`.

**Step B2 — Product lists files**

1. Start a **new** Claude Code session in your application repo.
2. Run `/memory` or `/context`.
3. Confirm personal `CLAUDE.md` (or the `@` import of `shared.md`) appears.

**Step B3 — Smoke test**

Continue to Lab C below.

---

### Gemini CLI

**Step B1 — File check**

```bash
head -20 ~/.gemini/GEMINI.md
```

Confirm the file exists and includes the Precedence block (the wire script
embeds `shared.md`).

**Step B2 — Product lists files**

1. Open a Gemini CLI session in your application repo.
2. Run:

   ```
   /memory refresh
   /memory show
   ```

3. Confirm `GEMINI.md` and repo `AGENTS.md` appear in the list.

**Android Studio Gemini is not Gemini CLI.** Do not use `/memory show` to verify
Studio.

**Step B3 — Smoke test**

Continue to Lab C below.

---

### Firebender

**Step B1 — File check**

```bash
ls -l ~/.firebender/rules/*.mdc
```

Confirm `personal-instructions.mdc` exists (written by the wire script).

Project `.cursor/rules/` in an app repo is **not** your personal wrapper.

**Step B2 — Product lists files**

1. Open your application repo in Android Studio with Firebender.
2. Start a **new** Firebender chat.
3. Ask:

   ```
   Quote the Precedence line from my personal prefs.
   ```

**Step B3 — Smoke test**

Continue to Lab C below.

---

**Lab B done when:** Each product you use passes file check and product lists
files.

---

## Lab C — Smoke test (10 minutes)

**Goal:** Confirm personal Goal / Ran / Doubt applies only when the **open
repo** does not name a PR body, and that **this workshop's** headings win
when it does.

Use the **same prompt** twice. Do **not** open or push a pull request. Switch
which folder is the project (File → Open Folder) between the two runs.

```
Draft a PR body for my current branch. Do not open or push a PR.
```

### Step C1 — No repo PR template (personal format)

Open an **application** repo whose `AGENTS.md` and `.cursor/rules/` do **not**
name PR body headings.

**Pass:** `## Goal`, `## Ran`, and `## Doubt`. Lab A put that format in
`shared.md` and in `~/.agents/rules/creating-pull-requests.mdc`.

If that application repo already requires Goal / Ran / Doubt, C1 still
matches the personal format. The contrast is C2.

### Step C2 — Workshop repo (repo template wins)

Open the cloned **ai-workshops** folder: the clone root, or
`workshops/customizing-agent-workflow`. Do **not** open `lab/` alone (that
folder has no `AGENTS.md`).

Same prompt.

**Pass:** `## What`, `## Why this repo`, and `## Verify`. Those headings live
in this repo's `AGENTS.md` and `.cursor/rules/pr-descriptions.mdc`.

**Fail:** The agent still uses Goal / Ran / Doubt and ignores the workshop
files.

If you fail, confirm the product’s workspace is the workshop clone (not the
app repo). Re-run the wire script if you use Cursor, Gemini, or Firebender
and you changed `shared.md`.

### Step C3 — Repeat in each product

Run C1 and C2 in Cursor, Claude, Gemini CLI, and/or Firebender — whichever
you verified in Lab B.

**Lab C done when:** C1 shows Goal / Ran / Doubt and C2 shows What / Why this
repo / Verify in at least one product you use daily.

---

## Lab D — Main thread plans (7 minutes)

**Goal:** Prove the Context cost lines in `shared.md` are loaded. The chat
you type in stays the planner. A **worker** explores.

Open your **application** repo (the large daily tree), not `lab/`.

### Step D1 — Paste this prompt

Do **not** add the word subagent unless nothing spawns. The Lab A template
already says spike unknowns in a subagent or a second session.

```
Keep this chat as the planner. Spike this unknown: commits, PR bodies, and Cloud Agents in this repo vs my personal PR headings. Short finding only. Do not paste file bodies.
```

Copy: [lab-d-prompt.md](lab-d-prompt.md).

### Step D2 — What pass looks like

| Product | Pass | Fail |
|---------|------|------|
| **Cursor** | A Task or subagent appears in the trace, then a short finding | This chat greps and pastes files |
| **Claude Code** | A Task or subagent runs; this chat stays the plan | Same dump in the main session |
| **Gemini CLI** | A **second session**, or a plan plus a short finding with no dump (this product has no subagent tool) | Huge exploration in the same session |
| **Firebender** | A worker if you see one; else same as Gemini | Same dump in this chat |

If nobody spawns, Lab B did not load the prefs. Re-check the wrapper, then
retry with: `Spike that unknown in a subagent.`

**Lab D done when:** Cursor or Claude shows a spawned worker, or Gemini uses a
second session, in at least one product you use daily.

---

## Quick reference — three-step verify (every product)

| Step | What you check |
|------|----------------|
| 1. File on disk | `shared.md` exists; Precedence block first; wire `--check` ok |
| 2. Product lists files | Cursor: new Agent chat. Claude: `/memory`. Gemini: `/memory show`. Firebender: quote test in chat. |
| 3. Smoke test | Prompt 2 cites repo commit rule |

---

## Troubleshooting

| Problem | What to do |
|---------|------------|
| Wire `--check` fails | Confirm `~/.agents/instructions/shared.md` exists and includes the Precedence line. Re-run `bash wire-personal-agents.sh` from `lab/`. |
| Wrapper conflict | The script will not overwrite an unmanaged `GEMINI.md`, Cursor wrapper, or Claude `CLAUDE.md`. Back up that file, or add the `managed-by: wire-personal-agents` markers, then re-run. |
| Claude does not show prefs | New session. Confirm `~/.claude/CLAUDE.md` contains `@~/.agents/instructions/shared.md`. Run `/memory`. |
| Gemini `/memory show` empty | Run `/memory refresh` first. Confirm you are in Gemini CLI, not Android Studio. Re-run the wire script after editing `shared.md`. |
| Firebender does not quote Precedence | Confirm `ls -l ~/.firebender/rules/` shows `personal-instructions.mdc`. Use a new chat. Re-run the wire script after editing `shared.md`. |
| Smoke test fail on commits | Remove duplicate commit lines from `shared.md`. Re-read Precedence block. Re-run prompt 2. |
| Cloud Agent ignores personal rules | Expected. Copy must-have prefs into repo `.cursor/rules/`, `AGENTS.md`, or Team Rules. See handout section 7 and [pr-author-packet-rule.md](../pr-author-packet-rule.md). |

---

## Related

- [lab/README.md](README.md) — setup commands and verify summary
- [handout.md](../handout.md) — full guide (precedence, Cloud, skills)
- [pr-author-packet-rule.md](../pr-author-packet-rule.md) — Goal / Ran / Doubt example
