# Sources: Subagents and lean context

Every claim in part 2 of the deck, and the tool facts in part 1, comes from the sources below. Quotes are copied from the pages as read on Nov 2, 2026. Tool docs change often; check them again before you re-run this workshop.

Labels:

- **Tool docs**: the vendor's own documentation for the tool.
- **Vendor post**: a vendor blog or engineering post, not reference docs.
- **Measured study**: a published experiment with stated models and tasks.
- **Early evidence**: a measured study on older models; the direction holds up in later work, but the numbers are from 2023 models.

## Part 1: subagents

### Claude Code: Create custom subagents (tool docs)

<https://code.claude.com/docs/en/sub-agents>

- Own context, same limits: a subagent has its own context window and "sends its own requests, which count toward the same usage limits as your main conversation."
- Invocation: "@-mention: guarantees the subagent runs for one task." "You can also type the mention manually without using the picker: `@agent-<name>` for local subagents."
- Reload: Claude Code "detects the change within a few seconds and the next delegation uses the updated definition, with no restart needed."
- Restart once: "If Claude can't find the new subagent, restart Claude Code and try again. This happens only when `~/.claude/agents/` didn't exist before the session started."
- Parallel work and its cost: "Running many subagents that each return detailed results can consume significant context, and each subagent spends tokens of its own while it runs."
- Frontmatter: the page lists `name` and `description` as required and describes the files Claude Code skips. Used for the lint rules and slide 9.
- Full parse: `claude plugin validate` (Claude Code v2.1.233 or later), as documented on the same page.

### Cursor: Subagents (tool docs)

<https://cursor.com/docs/subagents>

- Purpose: "Use subagents to break down complex tasks, do work in parallel, and preserve context in the main conversation."
- Invocation: "Request a specific subagent by using the `/name` syntax in your prompt."
- Locations: user subagents live in `~/.cursor/agents/` and `~/.claude/agents/` ("Claude compatibility"). "When multiple locations contain subagents with the same name, `.cursor/` takes precedence over `.claude/`." This is why the kit installs a copy for each tool.
- Fields: `description`, `model`, `readonly`, `is_background`; `name` is optional.
- Routing: "Include phrases like 'use proactively' or 'always use for' in your description field to encourage automatic delegation."
- How many: "Too many subagents: Start with 2-3."
- Cost: "Running five subagents in parallel uses roughly five times the tokens of a single agent."
- Built-in subagents: "These subagents were designed based on analysis of agent conversations where context window limits were hit." Used on slide 15.
- Fresh start: "A subagent doing a simple task may be slower than the main agent because it starts fresh."
- Not stated in these docs: how quickly Cursor picks up an edited agent file. The deck says only "if it does not show up yet, start a new chat."

## Part 2: why long sessions get worse

### Anthropic: Effective context engineering for AI agents (vendor post, 2025)

<https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>

- "As the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases."
- "These factors create a performance gradient rather than a hard cliff."
- Subagents: "Each subagent might explore extensively, using tens of thousands of tokens or more, but returns only a condensed, distilled summary of its work (often 1,000-2,000 tokens)."
- Structured note-taking outside the context window, used for the handoff note on slide 16.

### Chroma: Context Rot (measured study, 2025)

<https://research.trychroma.com/context-rot>

- Scope: "we evaluate 18 LLMs", from several model families.
- "Across all experiments, model performance consistently degrades with increasing input length."
- "Even a single distractor reduces performance relative to the baseline (needle only)."
- Focused versus full input: focused prompts "average to ~300 tokens" against the "full 113k" token input, with better results on the focused prompts.
- Caveat for facilitators: "Testing across 11 needle positions, we find no notable variation in performance for this specific NIAH task." The deck does not claim a position effect from this study; it uses Liu et al. for that, labeled as early evidence.

### Liu et al., Lost in the Middle (early evidence, 2023 models)

<https://arxiv.org/abs/2307.03172>

- Accuracy was highest when the relevant information sat at the start or end of the input and "significantly degrades" when it sat in the middle.
- Labeled on the deck as early evidence from 2023 models.

### Laban et al., LLMs Get Lost In Multi-Turn Conversation (measured study, 2025)

<https://arxiv.org/abs/2505.06120>

- "When LLMs take a wrong turn in a conversation, they get lost and do not recover."
- "an average drop of 39% across six generation tasks" when the same task is spread over several turns.
- The paper's finding that models make early assumptions and then rely on them is the basis for "a wrong turn sticks" on slide 12.
- Consolidate before retrying: you "can ask the LLM: “Please consolidate everything I’ve told you so far,” then bring the response to a new conversation." Used for the prompt on slide 12.
- The paper mentions coding tools in passing; the deck does not cite that part, because it is anecdotal.

### Claude Code: How Claude Code works (tool docs)

<https://code.claude.com/docs/en/how-claude-code-works>

- Compaction: Claude keeps the main points "and key code snippets, but detailed instructions from early in the conversation may be lost. Put persistent rules in CLAUDE.md rather than relying on conversation history."
- "run `/context` to see what's using space."
- "Each new session starts with a fresh context window."

### Claude Code: Best practices (tool docs)

<https://code.claude.com/docs/en/best-practices>

- "Running out of context is rarely the problem anymore. Subagents are still great for parallel work, keeping noisy output out of your way."
- "`/clear` between unrelated tasks. It costs nothing."
- "after two failed corrections run `/clear` and write a better prompt instead of a third."
- "`/compact` with a focus, like `/compact keep the API changes and the test commands`."
- "`/btw` ... answers a quick question without adding anything to the history." "`/rename oauth-migration` in the session names it, so that `claude --resume oauth-migration` from your shell picks it back up."
- Spec pattern: "Once `SPEC.md` exists, start a fresh session to build from it, so the build begins with a clean context and a written definition of done." Used on slide 16.
- MCP: "Connected servers add their tool names and instructions to the context even when you're not using them."

### Claude Code: Manage costs effectively (tool docs)

<https://code.claude.com/docs/en/costs>

- "Claude Code sends your full conversation with every request."
- "Stale context wastes tokens on every subsequent message."
- "`/compact` reads the conversation it summarizes, so compacting a large context is itself a large request."
- A `# Compact instructions` section in `CLAUDE.md` tells compaction what to keep.
- "Vague requests like 'improve this codebase' trigger broad scanning."

### Claude Code: Memory (tool docs)

<https://code.claude.com/docs/en/memory>

- "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence."
- `CLAUDE.md` loads every session; path-scoped rules (`paths:` frontmatter in `.claude/rules/`) load only for matching files. Used on slides 13 and 16.

### Cursor: Prompting agents, Context usage (tool docs)

<https://cursor.com/docs/agent/prompting>

- "When the window gets close to full, Cursor compresses older parts of the conversation into a summary."
- "The context ring next to your prompt input shows how full the window is at a glance. Click the ring to open the breakdown tray," split into system prompt, tools, rules, skills, MCP, subagents, summarized conversation and conversation.

### Cursor: Best practices for coding with agents (vendor post)

<https://cursor.com/blog/agent-best-practices>

- "After many turns and summarizations, the context accumulates noise and the agent can get distracted or switch to unrelated tasks."
- Start a new conversation when "You're moving to a different task or feature", "The agent seems confused or keeps making the same mistakes" or "You've finished one logical unit of work."
- Scope: "if you know the exact file, tag it." "Including irrelevant files can confuse the agent about what's important."
- "use `@Chats` to reference previous work rather than copy-pasting the whole conversation."

### Cursor: Rules (tool docs)

<https://cursor.com/docs/rules>

- "Keep rules under 500 lines." "Split large rules into multiple, composable rules." "Reference files" instead of copying their contents.
- Nested `AGENTS.md` files in subdirectories.

### Cursor: CLI slash commands and side chats (tool docs)

<https://cursor.com/docs/cli/reference/slash-commands> and <https://cursor.com/help/ai-features/side-chats>

- `/clear` (alias `/new`) starts a new chat; `/summarize` (alias `/compress`) summarizes to reduce context; `/fork` forks the chat into a new session.
- Side chats: type `/side` to "explore a side question or dig into a selection without crowding the main thread."

## Left out on purpose

- A keyboard shortcut for a new Cursor chat: only a third-party page gave one.
- A Cursor forum staff answer about rule adherence after summaries: a forum reply, not docs.
- Third-party blog summaries of the sources above: the deck cites the originals.
