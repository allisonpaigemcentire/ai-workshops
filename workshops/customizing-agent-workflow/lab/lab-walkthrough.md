# Lab walkthrough — Customizing Your Agent Workflow

Step-by-step guide for Labs A, B, and C. Time boxes match the 60-minute
workshop. Run only the steps for products you actually use.

**Before you start**

1. Open an application repo you use daily. It must already have `AGENTS.md`.
2. Clone this lab folder if you have not:

   ```bash
   git clone https://github.com/allisonpaigemcentire/ai-workshops.git
   cd ai-workshops/workshops/customizing-agent-workflow/lab
   ```

3. Keep [handout.md](../handout.md) open for reference. Use
   [verify-checklist.md](verify-checklist.md) at the end.

---

## Lab A — Write personal prefs (10 minutes)

**Goal:** Create **one** personal instruction file. Keep the Precedence block
and the three writing lines (no preamble, no trailing summary, state each
finding once). Add tool and cost lines that do not repeat your repo's
`AGENTS.md`.

### Step 1 — Copy the starter

From the `lab/` directory:

```bash
mkdir -p ~/.agents/instructions
cp templates/shared.md ~/.agents/instructions/shared.md
cp templates/agents.gitignore ~/.agents/.gitignore
git -C ~/.agents init
```

Do **not** copy this file into each product's home folder by hand. Lab B
points Claude, Cursor, Gemini, and Firebender at this one file.

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

### Step 4 — Save

Save only at `~/.agents/instructions/shared.md`.

**Lab A done when:** That file exists on disk and starts with the Precedence
block.

---

## Lab B — Wire and verify (17 minutes)

**Goal:** For each product you use, run the same three steps:

1. **File check** — canonical file on disk; wrapper points at it.
2. **Product lists files** — the tool shows your personal prefs loaded.
3. **Smoke test** — Lab C (next section).

### All products — run the wire script

From the cloned `lab/` directory:

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

## Lab C — Smoke test (7 minutes)

**Goal:** Confirm the **repo** wins when a personal habit could conflict.

Use the **same two prompts** in each product you verified in Lab B. Open your
application repo in that product before you start.

### Step C1 — Prompt 1 (personal habit)

```
Draft a PR body for my current branch.
```

If you have a PR author-packet personal rule, confirm `## Goal`, `## Ran`, and
`## Doubt` appear. If not, any structured body is fine for this workshop.

### Step C2 — Prompt 2 (repo must win)

```
What does AGENTS.md say about commits? Should you commit without me asking?
```

**Pass:** The agent cites the **repo** rule — for example, do not commit unless
you explicitly ask.

**Fail:** The agent follows only your personal line (for example, “commit when
I ask”) and ignores what `AGENTS.md` says.

If you fail, check whether your personal Defaults section duplicates commit
policy from the repo. Remove the duplicate from `shared.md` or align the
wording with the Precedence block. Re-run the wire script if you use Gemini
or Firebender.

### Step C3 — Repeat in each product

Run both prompts in Cursor, Claude, Gemini CLI, and/or Firebender — whichever
you verified in Lab B.

**Lab C done when:** Prompt 2 passes in at least one product you use daily.

---

## Exit checks (8 minutes)

**Goal:** Record what you verified. Leave with files on disk, not notes alone.

### Step 1 — Open the checklist

Open [verify-checklist.md](verify-checklist.md).

### Step 2 — Fill in each row

| Check | Your answer |
|-------|-------------|
| `~/.agents/instructions/shared.md` starts with Precedence line | Yes / No |
| **Wire** — `wire-personal-agents.sh --check` ok | Yes / No |
| **Cursor** — distinctive line or Precedence quote in new Agent chat | Yes / No / N/A |
| **Claude** — `/memory` lists personal `CLAUDE.md` or the `@` import | Yes / No / N/A |
| **Gemini CLI** — `/memory show` lists `GEMINI.md` and `AGENTS.md` | Yes / No / N/A |
| **Firebender** — `ls -l` ok; chat quotes Precedence | Yes / No / N/A |
| **Smoke test** — repo `AGENTS.md` wins on commits | Yes / No |
| Products verified today | _____________ |

Mark **N/A** for tools you do not use.

### Step 3 — Keep a copy

Save the checklist for yourself. Fix any **No** rows after the session using
[lab/README.md](README.md) and [handout.md](../handout.md).

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
- [verify-checklist.md](verify-checklist.md) — printable exit checklist
- [pr-author-packet-rule.md](../pr-author-packet-rule.md) — Goal / Ran / Doubt example
