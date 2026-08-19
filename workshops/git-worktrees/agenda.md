# Git Worktrees Workshop Agenda

| Topic | Notes |
|-------|-------|
| Welcome and outcomes | Open worktrees-presentation.html. Show slide 1–2: what you will do today. |
| Foundation: what a worktree is | Slide 3: what Git keeps separate vs. shared, the three rules, why it's not a full sandbox. |
| Core Git commands | Slide 4: show the commands. Point out the collapsible Claude Code / Cursor section. |
| Hands-on lab | Slides 5–12: pair lab. Each pair has their own clone of the playground repository. |
| Lab setup | Slide 5: check that the playground is clean. |
| Step 1: Create | Slide 6: create a worktree with `git worktree add -b`. |
| Step 2: Inspect | Slide 7: create a file, check it's only in the worktree. Expand the collapsible section. |
| Step 3: Observe guardrail | Slide 9: try to create another worktree on the same branch; Git refuses. |
| Challenge | Slide 10: what could you use for a temporary second checkout of the same commit? |
| Step 4: Cleanup | Slide 11: remove the file, remove the worktree, delete the branch. |
| Common mistakes | Slide 12: manual deletion vs. git removal; same branch in two worktrees. How to recover. |
| Apply: Claude Code and Cursor | Slide 13: map worktrees to Claude Code (`--worktree`) and Cursor (`/worktree`, `/best-of-n`, `/apply-worktree`). |
| Parallel vs. sequential | Slide 14: parallel workflows on different tasks with real-world examples; sequential handoff workflows. |
| Fleet view | Slide 15: launching many agents in parallel, each with its own worktree and PR; tracking with git and gh commands. |
| Fleet view challenge | Slide 16: try parallel agents in Claude Code (Agent with `isolation: "worktree"`) or sequential in Cursor (`/worktree` commands). |
| Nuuly conventions | Slide 17: naming and patterns specific to Nuuly workflows. |
| Close: choose the right tool | Slide 18: decision table. Slide 19: resources and three-line playbook. |
