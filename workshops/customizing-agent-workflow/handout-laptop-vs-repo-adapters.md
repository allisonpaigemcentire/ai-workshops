# Laptop wrappers vs repo adapters

Companion to [handout.md](handout.md)
and practices-deck slide 7 (Point tools at it).

**Soundbite:** The wire script and the product share a machine. A repo hook
writes files the clone does not see, and the clone does not run your hook.

---

## What this handout is for

Two setups look alike:

1. **Laptop:** `lab/wire-personal-agents.sh` writes Claude / Cursor / Gemini /
   Firebender wrappers that follow `~/.agents/instructions/shared.md`.
2. **Repo:** a SessionStart `.sh` in an application tree (RMS in
   `r15-services-customer` did this) creates `CLAUDE.md` or skill-discovery
   links when Claude Code starts.

Both “create wrappers so Claude can see the canonical file.” Only (1) is
allowed. This note is why.

---

## Two different consumers

| | Personal wrappers | Repo adapters |
|---|-------------------|---------------|
| Canonical file | `~/.agents/instructions/shared.md` | `AGENTS.md` in the clone |
| Who must see it | Products **on this laptop** | Every teammate, Cloud Agent, and tool that opens the **clone** |
| Where the adapter lives | Home directory (`~/.claude/`, `~/.cursor/`, …) | Inside the git tree (`CLAUDE.md`, `.claude/skills/`, …) |
| Who runs the generator | You, on this machine | Git checkout — **no generator runs** |

The generator is allowed only when the reader of the files is the same
machine that ran the generator.

---

## Why the laptop script is allowed

`wire-personal-agents.sh` runs on your laptop and writes files those same
laptop products already load:

| Product | Wrapper | What it does |
|---------|---------|--------------|
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/instructions/shared.md` (live after body edits) |
| Cursor | `~/.cursor/rules/personal-instructions.mdc` | Embedded copy of `shared.md` |
| Gemini / Antigravity | `~/.gemini/GEMINI.md` | Embedded copy |
| Firebender | `~/.firebender/rules/personal-instructions.mdc` | Embedded copy |

That is a **local adapter**. Cursor Agent on this machine reads
`~/.cursor/rules/`. Claude Code on this machine reads `~/.claude/CLAUDE.md`.
You ran the script; those products are right there.

Cursor Cloud Agents never load `~/.agents/` or `~/.cursor/rules/` from your
laptop. That is expected. If a pref must apply on Cloud, it belongs in the
repo harness or Team Rules — see the main handout, section 7. The wire
script is not a Cloud delivery mechanism.

Re-run the script after you edit `shared.md` if you use Cursor, Gemini, or
Firebender. Those wrappers embed a copy. Claude’s `@` import stays live.

---

## Why a repo SessionStart script is not allowed

RMS used a Claude Code **SessionStart** hook: a `.sh` that created adapter
files (Claude skill links, and historically Claude context) when a session
started in `rms/`.

That hook is a generator that **only Claude Code runs**, and **only if** the
session starts in the directory that owns `rms/.claude/settings.json`.

What never runs that hook:

- `git clone` / `git pull`
- Cursor (it does not execute Claude SessionStart)
- Gemini CLI / Antigravity / Firebender
- Cursor Cloud Agents (they see the clone, not your last local Claude start)
- A teammate who starts Claude at the **monorepo root** instead of `rms/`

So the wrappers exist only on machines that already launched Claude from
`rms/`. Everyone else sees a tree with no adapter — or a dirty working tree
full of generated files that were never reviewed.

That is the same failure as putting `@~/.agents/instructions/shared.md` in a
repo `CLAUDE.md`: the clone does not contain the target, and nothing in git
creates it.

RMS now documents the replacement: commit a relative `rms/CLAUDE.md` →
`rms/AGENTS.md` symlink, and commit `.claude/skills/` → `.agents/skills/`
as a **directory** symlink. Do not generate those links in a session hook.
Adding a skill under `.agents/skills/` is enough; the directory symlink
picks it up.

---

## Same idea, wrong layer

| Pattern | Layer | Verdict |
|---------|--------|---------|
| `wire-personal-agents.sh` → `~/.claude/CLAUDE.md` | Laptop | Keep |
| SessionStart `.sh` → repo `CLAUDE.md` / per-skill links | Repo | Remove |
| Committed `CLAUDE.md` → `AGENTS.md` relative symlink | Repo | Keep |
| `@AGENTS.md` import inside a real repo `CLAUDE.md` | Repo | Avoid (second file; double-load; Claude-only magic) |
| `@~/.agents/...` inside a repo file | Repo | Never (home path is not in the clone) |

The wire script is not “hooks are good, so put one in the repo.” It is
“this machine’s products need a pointer at this machine’s file.”

---

## What goes wrong if you keep the repo script

1. **Cloud and teammates miss the harness.** The clone is the contract.
   Generated adapters are not in the contract.
2. **Start-directory bugs.** SessionStart in `rms/.claude/settings.json`
   does not run when Claude starts at repo root. Skills and `CLAUDE.md`
   appear “flaky” depending on cwd.
3. **Reviewers cannot see the adapter.** Generated files are gitignored, or
   they show up as unreviewed local dirt. A relative symlink is git
   metadata. `git ls-files` and `ls -l CLAUDE.md` agree.
4. **New skills wait on the hook.** Per-skill links created at session start
   mean a new skill is invisible until someone runs Claude in that folder
   again. A directory symlink does not need that step.
5. **Claude-only.** Cursor and Gemini already read `.agents/skills/` and
   `AGENTS.md`. A Claude hook does not help them, and it trains the team to
   think “the harness exists because Claude created it.”

---

## What to do instead

**Personal (this workshop)**

```bash
# From the cloned lab/ folder, after shared.md exists:
bash wire-personal-agents.sh
bash wire-personal-agents.sh --check
```

Edit `~/.agents/instructions/shared.md` once. Do not copy it into the
application repo.

**Repo (application / services trees)**

- One canonical `AGENTS.md` (nearest file to the edited code wins).
- At each Claude **session root**, commit `ln -s AGENTS.md CLAUDE.md`
  (relative). Do not leave a second rulebook under the import.
- Canonical skills in `.agents/skills/`. Claude gets a committed
  `.claude/skills` → `.agents/skills` directory symlink when one local
  source is enough.
- Do not add a SessionStart script whose job is to create those adapters.

Claude Code docs still allow `@AGENTS.md` inside `CLAUDE.md`. This org
commits the symlink so `CLAUDE.md` **is** `AGENTS.md` — one document, two
names — and so Cursor / Cloud / `cat` do not depend on Claude expanding
`@`.

---

## How to say it in the room

> Laptop: the script and the product share a machine. Repo: the product
> only sees the clone, and the clone does not run your hook.

If someone asks why RMS removed the SessionStart generator: the clone is
what teammates and Cloud get. Adapters that exist only after Claude starts
are not in the clone.

---

## Related

| Doc | What it is |
|-----|------------|
| [handout.md](handout.md) | Main workshop handout (precedence, wire script, Cloud) |
| Practices deck slide 7 | Point tools at it. Do not copy by hand. |
| [pr-author-packet-rule.md](pr-author-packet-rule.md) | Cloud: promote into the repo, do not symlink home into git |
| [agents.md](https://agents.md/) | Nearest `AGENTS.md` wins; symlink legacy names |
| [Claude Code memory](https://code.claude.com/docs/en/claude-md) | `CLAUDE.md` loads; symlink or `@AGENTS.md` |
