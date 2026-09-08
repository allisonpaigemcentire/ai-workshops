# Facilitator runbook — Customizing Your Agent Workflow (60 minutes)

**Audience:** Nuuly engineers who use Cursor, Claude Code, Gemini CLI,
Antigravity, and/or Firebender  
**Duration:** 60 minutes  
**Status:** Draft  
**Handout:** [handout.md](handout.md)  
**Deck:** [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html)  
**Participant lab:** [lab/README.md](lab/README.md)

**Takeaway line:** Personal prefs fill gaps on this machine. Repo `AGENTS.md`,
skills, hooks, and rules still win on conflict.

**Out of scope (this cut):** Personal skills and subagents (handout sections
11–12; deck slide 30). Take-home reading only.

---

## Agenda

| Time | Segment | Goal |
|------|---------|------|
| **0:00–0:08** | **Frame** | Repo files win. Hooks stop; markdown advises. Deck slides 1–3 and 13. |
| **0:08–0:18** | **Map the stack and the gaps** | Five layers; Cloud Agents do not load `~/.cursor/rules`; Claude loads every `~/.claude/rules` file; Gemini and Firebender are not on the Cursor↔Claude sync script. Deck slides 5, 15, 18–20, 26 (verify). Skip slides 10–12 unless a question forces it. |
| **0:18–0:28** | **Lab A — write prefs** | Each person writes 5–10 personal lines from handout section 10, starting with the Precedence block. Save as `~/.cursor/rules/*.mdc` with `alwaysApply: true` for always-on lines. People who do not use Cursor write the same text into the file their tool reads (Lab B). |
| **0:28–0:45** | **Lab B — wire and verify** | Run only the products each person uses. Same three-step verify for Claude, Gemini CLI, and Firebender (below). Facilitator demos any tool the room lacks. |
| **0:45–0:52** | **Lab C — smoke test** | Same two prompts in each verified product. Pass = repo `AGENTS.md` wins on commits when it conflicts with a personal habit. |
| **0:52–1:00** | **Exit checks + close** | Fill the checklist. Point at [handout.md](handout.md), [lab/README.md](lab/README.md), and [pr-author-packet-rule.md](pr-author-packet-rule.md). Deck slides 32–33. |

---

## Live vs skip slide list

**Live path (18 minutes talk + labs):** 1–3, 5, 13, 15, 18–20, 26, 32–33

**Skip unless Q&A:** 4, 6–12, 14, 16–17, 21–25, 27–31

**Take-home:** slide 30 (skills and subagents)

---

## Lab A — write prefs (0:18–0:28)

**Prompt to the room**

> Write five to ten personal lines that do not repeat your repo's `AGENTS.md`.
> Start with the Precedence block from handout section 10. Add one distinctive
> line you can test later — for example: "End every reply with what happens
> next."

**Where to save**

| Product | Path |
|---------|------|
| Cursor (canonical for most people) | `~/.cursor/rules/personal-workflow.mdc` |
| Claude only (no Cursor) | Same text in `~/.claude/CLAUDE.md` or a file under `~/.claude/rules/` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` |
| Firebender | `~/.firebender/rules/personal-workflow.mdc` |

**Minimal `.mdc` frontmatter (Cursor / Firebender)**

```yaml
---
description: Personal workflow prefs for this machine
alwaysApply: true
---
```

**Minimal `GEMINI.md` opener**

```markdown
# Personal prefs. Repo AGENTS.md, skills, and hooks win on conflict.
```

---

## Lab B — wire and verify (0:28–0:45)

Run only the rows each person uses. All three products follow the same pattern:
**file check → product lists loaded files → new session smoke test** (Lab C).

### Cursor

1. **File check:** `ls ~/.cursor/rules/*.mdc` — personal file exists and starts
   with the Precedence line.
2. **Product lists files:** Start a new Agent chat. Ask: "What personal rules
   from ~/.cursor/rules are loaded?" or confirm a distinctive line from Lab A
   appears in behavior.
3. **Smoke test:** Lab C prompts (below).

**Note:** Cursor Cloud Agents do not load `~/.cursor/rules/`. If someone asks,
point at handout section 7 and slide 26.

### Claude Code

1. **File check:** From the workshop `lab/` directory:

   ```bash
   bash sync-personal-rules.sh
   bash sync-personal-rules.sh --check
   ```

   Expect: `Personal rules bridge: ok (N Cursor rule(s))`.

2. **Product lists files:** Start a new Claude Code session. Run `/memory` or
   `/context`. Confirm mirrored rules from `~/.claude/rules/` appear.

3. **Smoke test:** Lab C prompts.

**Note:** Claude loads every file in `~/.claude/rules/` and ignores
`alwaysApply: false`. Put Cursor-only stems in `~/.cursor/rules/.claude-exclude`
and re-run sync.

### Gemini CLI and Antigravity

1. **File check:** `~/.gemini/GEMINI.md` exists and starts with the Precedence
   line (or the opener above).

2. **Product lists files:** In an active Gemini CLI session:

   ```
   /memory refresh
   /memory show
   ```

   Confirm `GEMINI.md` and repo `AGENTS.md` appear in the list.

3. **Smoke test:** Lab C prompts.

**Note:** Antigravity global rules use the same `~/.gemini/GEMINI.md`. Android
Studio Gemini is **not** Gemini CLI. Do not score Studio against `/memory show`.

### Firebender

1. **File check:**

   ```bash
   ls -l ~/.firebender/rules/*.mdc
   ```

   Each entry is a real file or a symlink into `~/.cursor/rules/`. Firebender
   documents symlink support.

   Optional symlink from Cursor canonical source:

   ```bash
   mkdir -p ~/.firebender/rules
   ln -sfn ~/.cursor/rules/personal-workflow.mdc ~/.firebender/rules/personal-workflow.mdc
   ```

2. **Product lists files:** Firebender has no documented `/memory show`. In a
   **new** Firebender chat, ask:

   > Name the personal rule files under ~/.firebender/rules and quote the
   > Precedence line from my personal-workflow rule.

3. **Smoke test:** Lab C prompts in Firebender chat.

**Note:** Project `.cursor/rules/` in the repo is not `~/.cursor/rules/`.
Personal Cursor rules reach Firebender only via `~/.firebender/rules/` (copy
or symlink). Do not symlink Cursor-only Cloud Agents workarounds into
Firebender.

---

## Lab C — smoke test (0:45–0:52)

Use the **same two prompts** in each product verified in Lab B.

**Prompt 1 — personal habit (optional PR format)**

```text
Draft a PR body for my current branch.
```

If the person has a PR author-packet rule, confirm `## Goal`, `## Ran`, and
`## Doubt` appear. If not, any structured body is fine for this workshop.

**Prompt 2 — repo wins**

```text
What does AGENTS.md say about commits? Should you commit without me asking?
```

**Pass:** The agent cites the **repo** rule (for example: do not commit unless
explicitly asked). **Fail:** The agent follows only the personal line and
ignores `AGENTS.md`.

**Facilitator debrief (one minute):** Personal prefs advise. Repo harness wins.
That is the point of the Precedence block.

---

## Exit checks

One row per person. Mark **N/A** for products they do not use.

| Check | Pass |
|-------|------|
| Personal file starts with Precedence line | Yes / No |
| **Cursor** — distinctive line or rule list in new Agent chat | Yes / No / N/A |
| **Claude** — `sync-personal-rules.sh --check` ok; `/memory` lists rules | Yes / No / N/A |
| **Gemini CLI** — `/memory show` lists `GEMINI.md` and `AGENTS.md` | Yes / No / N/A |
| **Firebender** — `ls -l ~/.firebender/rules/*.mdc` ok; chat quotes Precedence | Yes / No / N/A |
| **Smoke test** — repo `AGENTS.md` wins on commits | Yes / No |
| **Written** — which products verified today | _____________ |

**Success signal:** Attendees leave with a personal file on disk and a completed
verify row for each product they use — not tip notes alone.

---

## Facilitator dry-run (before the room)

Run once on the facilitator machine. Goal: confirm timing, demo paths, and that
each verify command works.

### Checklist

1. [ ] Open [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) in a browser. Walk live-path slides 1–3, 5, 13, 15, 18–20, 26, 32–33.
2. [ ] Workshop `lab/` folder present. `bash sync-personal-rules.sh --check` succeeds from that directory.
3. [ ] `~/.cursor/rules/personal-workflow.mdc` (or demo file) exists with Precedence block and one distinctive test line.
4. [ ] Claude: new session; `/memory` lists mirrored rules.
5. [ ] `~/.gemini/GEMINI.md` exists with Precedence opener. Gemini CLI: `/memory refresh` then `/memory show` lists it.
6. [ ] `~/.firebender/rules/personal-workflow.mdc` exists (file or symlink). New Firebender chat quotes Precedence line.
7. [ ] Smoke test in one product: repo commit rule wins over personal habit.
8. [ ] Rehearse talk path to **18 minutes** with shortened slide list.
9. [ ] Prepare fallback: if Gemini CLI is unavailable, demo `/memory show` from facilitator screen; attendees still run file check + smoke test on their machines later.
10. [ ] Prepare fallback: if Firebender seat unavailable, show `ls -l` output and the quote prompt on screen; Android attendees verify after class.

### Facilitator risks

- **Gemini/Firebender skipped as "homework"** — Lab B treats them as first-class. No script is not the same as optional.
- **Android Studio Gemini vs Gemini CLI** — Do not score Studio against `/memory show`.
- **Claude context bloat** — If someone mirrored too many Cursor rules, point at `.claude-exclude` and handout section 5.
- **Cloud Agents confusion** — Personal rules do not load on Cloud. Promotion path is handout section 7 and [pr-author-packet-rule.md](pr-author-packet-rule.md).

---

## Materials

| File | Role |
|------|------|
| [customizing-your-agent-workflow.md](customizing-your-agent-workflow.md) | Main handout |
| [customizing-your-agent-workflow-slides.html](customizing-your-agent-workflow-slides.html) | Screen-share deck |
| [handout.md](handout.md) | Main participant handout |
| [lab/README.md](lab/README.md) | Participant lab setup and verify |
| [lab/sync-personal-rules.sh](lab/sync-personal-rules.sh) | Sync script |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Goal / Ran / Doubt + Cloud promotion example |
| [firebender-claude-notes.md](../claude-code-and-cursor/firebender-claude-notes.md) | Android Firebender ↔ Claude pairing |

**Room needs:** Laptops, at least one application repo with `AGENTS.md`, and
access to the tools each person actually uses.

---

## Close script (~2 minutes)

> You wrote personal prefs that apply on this machine. The repo still teaches
> the codebase. If a personal rule and `AGENTS.md` disagree, follow the repo.
>
> Cursor and Claude share one source through the sync script in `lab/`. Gemini and
> Firebender need the same text in their home folders — and the same three-step
> verify: file on disk, product shows it loaded, smoke test confirms repo wins.
>
> If you use Cursor Cloud Agents, promote must-have prefs into the repo or Team
> Rules before you start a Cloud run. The handout section 7 and
> pr-author-packet-rule.md walk through that.
>
> Skills and subagents are in the handout for take-home. Start with prefs that
> load everywhere you actually work.

---

## Related

- Workshops index: [../README.md](../README.md)
- Guardrails workshop (hooks vs markdown): [../guardrails/](../guardrails/)
