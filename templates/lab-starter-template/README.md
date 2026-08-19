# Lab starter template

Use this folder as the starting point for a hands-on lab that needs its own git
history — for example, a workshop where participants make commits, create
branches, or use worktrees.

## How to use this template

1. Copy this folder out to its own location (not inside `ai-workshops`).
2. Replace this README with the participant-facing lab instructions.
3. Run `git init`, add the starter files, and make one initial commit.
4. Push it as its own repository (for example named `ai-workshops-lab-<slug>`).
5. In the matching workshop's `lab/README.md` inside `ai-workshops`, link to this
   repository and give the clone command, for example:

   ```bash
   git clone <repository-url> participant-playground
   ```

6. For a live session, the facilitator clones this repository fresh once per
   participant or pair before the session starts.

## Why this is a separate repository, not a folder inside ai-workshops

A git repository nested inside another git repository (a folder containing its
own `.git` directory) cannot be cloned by participants using a URL, and is not
visible to normal `git status` in the parent repository the way tracked files
are. Pushing it as its own repository avoids both problems.
