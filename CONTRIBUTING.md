# Adding a new workshop

1. Copy `templates/workshop-template/` to `workshops/<descriptive-kebab-case-slug>/`.
   Name the folder for what the workshop teaches, not a project codename.
2. Fill in the copied `README.md`: audience, duration, prerequisites, what
   participants leave with.
3. Fill in `agenda-<N>min.md` with the run-of-show for the session length you plan
   to run (rename the file to match, for example `agenda-60min.md`).
4. Fill in `facilitator-guide.md` with timing notes and, once you have run the
   workshop at least once, an answer key. This file is facilitator-only — never
   point participants at it.
5. Put anything participants will actually open or clone under `lab/`. Keep this
   folder clean enough to be the literal clone target — no facilitator notes, no
   internal names, no unrelated files.
6. If the lab needs its own git history (branches, commits, worktrees) rather than
   just a folder of starter files, do not nest a second git repository inside this
   one. Instead:
   - Create a new, separate repository and push it (for example
     `ai-workshops-lab-<slug>`).
   - Replace the `lab/` folder in this repo with a `lab/README.md` that links to
     the separate repository and gives the clone command.
7. Add a row to the workshop index table in the top-level `README.md`.
8. When a workshop is retired, move its folder from `workshops/` to `_archive/`
   rather than deleting it.
