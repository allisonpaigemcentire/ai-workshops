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

**Goal:** Create a personal instruction file with five to ten lines that do
not repeat your repo's `AGENTS.md`. Start with the Precedence block.

### Step 1 — Copy a starter template (optional)

From the `lab/` directory:

**Cursor (most people use this as the canonical source)**

```bash
mkdir -p ~/.cursor/rules
cp templates/personal-workflow.mdc ~/.cursor/rules/personal-workflow.mdc
```

**Gemini CLI or Antigravity (if you do not use Cursor, or in addition)**

```bash
mkdir -p ~/.gemini
cp templates/GEMINI.md ~/.gemini/GEMINI.md
```

**Firebender**

```bash
mkdir -p ~/.firebender/rules
cp templates/personal-workflow.mdc ~/.firebender/rules/personal-workflow.mdc
```

**Claude Code only (no Cursor)**

Copy the same text into `~/.claude/CLAUDE.md` or a file under
`~/.claude/rules/`. Skip the sync script until you also use Cursor.

### Step 2 — Keep the Precedence block at the top

Your file must start with this block (already in the template):

```markdown
## Precedence

Repo `AGENTS.md`, `.agents/skills/`, repo hooks, and repo rules win.
These lines are personal prefs for this machine. On conflict, follow the repo.
```

For Cursor and Firebender `.mdc` files, keep this frontmatter:

```yaml
---
description: Personal workflow prefs for this machine
alwaysApply: true
---
```

For `~/.gemini/GEMINI.md`, the template opens with a one-line summary, then
the same Precedence block.

### Step 3 — Replace boilerplate with your own lines

1. Delete or edit the example sections (`How I work`, `Tooling`, etc.).
2. Write five to ten lines that are **yours** — writing style, tool habits,
   cost prefs. Do **not** copy branch rules, commit flags, package managers,
   or generate-client commands from the repo.
3. Add **one distinctive test line** you can check in Lab B. Example from the
   template: `End every reply with what happens next.` Remove that line after
   you confirm it loaded.

### Step 4 — Save to the right path

| Product | Save here |
|---------|-----------|
| Cursor | `~/.cursor/rules/personal-workflow.mdc` |
| Claude only | `~/.claude/CLAUDE.md` or `~/.claude/rules/*.md` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` |
| Firebender | `~/.firebender/rules/personal-workflow.mdc` |

**Lab A done when:** Your file exists on disk and starts with the Precedence
block.

---

## Lab B — Wire and verify (17 minutes)

**Goal:** For each product you use, run the same three steps:

1. **File check** — file on disk, Precedence block present.
2. **Product lists files** — the tool shows your personal rules loaded.
3. **Smoke test** — Lab C (next section).

Run only the product sections below that apply to you.

### Cursor

**Step B1 — File check**

```bash
ls ~/.cursor/rules/*.mdc
```

Confirm `personal-workflow.mdc` (or your file) exists. Open it and confirm the
Precedence block is first.

**Step B2 — Product lists files**

1. Open your application repo in Cursor.
2. Start a **new** Agent chat.
3. Ask: `What personal rules from ~/.cursor/rules are loaded?`
   Or confirm your distinctive test line appears in replies.

**Step B3 — Smoke test**

Continue to Lab C below.

**Note:** Cursor Cloud Agents do **not** load `~/.cursor/rules/`. If you use
Cloud, promote must-have prefs into the repo or Team Rules (handout section 7).

---

### Claude Code

**Step B1 — File check and sync**

From the cloned `lab/` directory:

```bash
bash sync-personal-rules.sh
bash sync-personal-rules.sh --check
```

**Expected output:** `Personal rules bridge: ok (N Cursor rule(s))`

If you do not use Cursor, skip the sync script. Your Claude personal file from
Lab A is enough.

**Optional:** If you have Cursor-only rules that should not mirror to Claude,
copy `templates/claude-exclude.example` to `~/.cursor/rules/.claude-exclude`,
add rule stems (one per line), then re-run sync.

Re-run sync after you **add, rename, or remove** a file in `~/.cursor/rules/`.
You do **not** need to re-run after editing the body of an existing `.mdc`.

**Step B2 — Product lists files**

1. Start a **new** Claude Code session in your application repo.
2. Run `/memory` or `/context`.
3. Confirm mirrored rules from `~/.claude/rules/` appear.

**Step B3 — Smoke test**

Continue to Lab C below.

---

### Gemini CLI

**Step B1 — File check**

```bash
cat ~/.gemini/GEMINI.md | head -20
```

Confirm the file exists and starts with the Precedence block (or the template
opener plus Precedence).

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

Each entry should be a real file or a symlink. Optional symlink from Cursor:

```bash
mkdir -p ~/.firebender/rules
ln -sfn ~/.cursor/rules/personal-workflow.mdc ~/.firebender/rules/personal-workflow.mdc
ls -l ~/.firebender/rules/
```

Project `.cursor/rules/` in an app repo is **not** `~/.cursor/rules/`. Personal
Cursor rules reach Firebender only through `~/.firebender/rules/`.

**Step B2 — Product lists files**

1. Open your application repo in Android Studio with Firebender.
2. Start a **new** Firebender chat.
3. Ask:

   ```
   Name the personal rule files under ~/.firebender/rules and quote the
   Precedence line from my personal-workflow rule.
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
policy from the repo. Remove the duplicate from your personal file or align the
wording with the Precedence block.

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
| Personal file starts with Precedence line | Yes / No |
| **Cursor** — distinctive line or rule list in new Agent chat | Yes / No / N/A |
| **Claude** — `sync-personal-rules.sh --check` ok; `/memory` lists rules | Yes / No / N/A |
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
| 1. File on disk | Personal file exists; Precedence block first |
| 2. Product lists files | Cursor: new Agent chat. Claude: `/memory`. Gemini: `/memory show`. Firebender: quote test in chat. |
| 3. Smoke test | Prompt 2 cites repo commit rule |

---

## Troubleshooting

| Problem | What to do |
|---------|------------|
| Sync `--check` fails | Run `bash sync-personal-rules.sh` again from `lab/`. Check for broken symlinks in `~/.claude/rules/`. |
| Claude loads too many rules | Add Cursor-only stems to `~/.cursor/rules/.claude-exclude`. Re-run sync. |
| Gemini `/memory show` empty | Run `/memory refresh` first. Confirm you are in Gemini CLI, not Android Studio. |
| Firebender does not quote Precedence | Confirm `ls -l ~/.firebender/rules/` shows your file. Use a new chat, not an old thread. |
| Smoke test fail on commits | Remove duplicate commit lines from personal file. Re-read Precedence block. Re-run prompt 2. |
| Cloud Agent ignores personal rules | Expected. Copy must-have prefs into repo `.cursor/rules/`, `AGENTS.md`, or Team Rules. See handout section 7 and [pr-author-packet-rule.md](../pr-author-packet-rule.md). |

---

## Related

- [lab/README.md](README.md) — setup commands and verify summary
- [handout.md](../handout.md) — full guide (precedence, Cloud, skills)
- [verify-checklist.md](verify-checklist.md) — printable exit checklist
- [pr-author-packet-rule.md](../pr-author-packet-rule.md) — Goal / Ran / Doubt example
