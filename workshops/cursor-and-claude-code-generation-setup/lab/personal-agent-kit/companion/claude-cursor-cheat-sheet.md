# When to switch — Claude Code + Cursor cheat sheet

Reference for the 30-minute blind-review comparison.
Supported tools: Cursor, Claude Code and Gemini CLI.

## Role split

| Role | Cursor | Claude Code |
|------|--------|-------------|
| Best for | Inline edits, Tab, visual diffs, tight UI polish | Multi-file campaigns, plan→execute→test, repo-wide explore |
| Latency | Seconds | Minutes |
| Review surface | Source Control / editor diffs | Diff-first prompts, CLI output |

## Decision heuristic

- **Small, visible, local** → Cursor
- **Ambiguous, multi-file, long-running** → Claude Code
- **Unsure** → Claude plans; Cursor applies the small slice; Claude verifies

## Claude Code inside Cursor (same window)

1. Install the **Claude Code extension** in Cursor (sidebar / plan / checkpoints) — optional if you only use the CLI.
2. Put `claude` on **PATH** and open Cursor’s **integrated terminal** (required for dual-tool verify).
3. Layout: **editor left, Claude terminal right**.
4. Extension and CLI share settings / `CLAUDE.md` / MCP.
5. Optional: in an external terminal, `/ide` links Claude to Cursor’s diff viewer.

Keep the completed review packet in the clipboard. The project-isolated judge
runs once as Claude CLI **from Cursor’s terminal**:

```bash
JUDGE_DIR="$(mktemp -d)"
cd "$JUDGE_DIR"
pbpaste | claude -p --safe-mode --tools "" --no-session-persistence
```

## Install + SSO login (CLI)

Org seats use Claude for Teams / Enterprise with **SSO**. Use your **work email**, not a personal Claude.ai account.

1. Install:

```bash
curl -fsSL https://claude.ai/install.sh | bash
# or: brew install --cask claude-code
```

2. Confirm PATH:

```bash
which claude && claude --version
# if missing: export PATH="$HOME/.local/bin:$PATH"  (add to ~/.zshrc)
```

3. Log in with SSO:

```bash
claude auth login --sso
# optional: claude auth login --sso --email you@yourcompany.com
```

Complete the browser IdP login (Okta / Entra / etc.). If the browser shows a code instead of redirecting, paste it into the terminal.

4. Verify:

```bash
claude auth status --text
# or: claude
```

5. Re-auth if needed:

```bash
claude auth logout
claude auth login --sso --email you@yourcompany.com
```

**Do not** use `--console` or set `ANTHROPIC_API_KEY` for normal org seats unless an admin told you to — those can override subscription SSO.

| Symptom | Try |
|---------|-----|
| Personal Claude account | Logout → `claude auth login --sso` with work email |
| Auth option missing | `claude update`, then retry SSO |
| Browser never returns | Press `c` to copy URL; paste one-time code if shown |
| Wrong credential wins | `unset ANTHROPIC_API_KEY`; check `/status` |

## Ritual: git is the contract

1. One AI edits at a time.
2. `git status` / `git diff --stat` before touching the other tool.
3. Same acceptance criteria in both passes.
4. Human owns the commit (`git add -p` if needed).

## Independent-review stress test

1. Plant a false product clarification in the Cursor authoring chat.
2. Cursor summarizes, implements, tests, and justifies that false rule.
3. Give the same completed review packet to that Cursor chat and a fresh,
   tool-free Claude CLI session.
4. Neither reviewer reads files or runs tools during review.
5. Reveal the false prior chat after both verdicts.
6. State clearly: this tests prior-chat influence, not general model accuracy.

## Shared harness (three layers)

1. **Repo:** `AGENTS.md` + skills + thin `CLAUDE.md` / Cursor rules
2. **Personal layer:** `~/.agents/` wired into Cursor, Claude Code and Gemini by this kit's `scripts/install.sh` — [personal-rules-bridge.md](personal-rules-bridge.md)
3. **Personal memory:** `~/.ai-memory/` so Cursor and Claude share durable lessons — wrap up after corrections

## Hygiene

- Do not let both tools edit the same files at once
- New Cursor chat / Claude `/clear` between unrelated tasks
- Parallel agents → separate git worktrees

## 3-line personal playbook (fill at close)

1. Default for small edits: _______________
2. Default for repo-wide / long work: _______________
3. Verification gate before merge: _______________
