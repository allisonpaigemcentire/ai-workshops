# Enable LSP (code intelligence) for agents

> Adapted from a community kit of local agent optimizations.

Gives the agent symbol-aware navigation and immediate type-error feedback
instead of text search.

## Why

**Documented** (Claude Code docs)
- Finds definitions and references "by symbol instead of by text search".
- Diagnostics catch type errors and missing imports "without running a
  compiler", reported after each edit.
- The `LSP` tool is read-only.

**Inference (not in docs)**
- Fewer grep hits to read, so less context loaded and lower cost per turn.
- Fewer wrong-symbol matches (same-name symbols, comments, strings).
- The agent sees its own type errors right away, so fewer broken
  edit-then-compile cycles.

No measured token savings.

## Claude Code setup

The LSP tool stays inactive until a code intelligence plugin is installed.
Two steps per language:

1. Install the language-server binary. Binaries are not bundled and must be
   on the `PATH` of the shell that launches `claude`.
2. Install the plugin inside a `claude` session:
   `/plugin install <plugin>@claude-plugins-official`

| Language | Plugin | Binary | Install hint | Check |
|----------|--------|--------|--------------|-------|
| Python | `pyright-lsp` | `pyright-langserver` | `npm i -g pyright` or `pip install pyright` | `which pyright-langserver` |
| TS / JS | `typescript-lsp` | `typescript-language-server` | `npm install -g typescript-language-server typescript` | `which typescript-language-server` |
| Swift | `swift-lsp` | `sourcekit-lsp` | Ships with Xcode / the Swift toolchain | `which sourcekit-lsp` |
| Kotlin | `kotlin-lsp` | `kotlin-lsp` | See the plugin README | `which kotlin-lsp` |

Other languages: browse the official marketplace with `/plugin`.

### Verify

1. Restart the session after installing a binary.
2. Ask Claude to introduce, then fix, a type error in a matching file. The
   server starts on the first edit of that file type.
3. Expect: `Found N new diagnostic issues in M files (ctrl+o to expand)`.
4. Nothing shown: run `/plugin` and open the Errors tab.
   `Executable not found in $PATH: "<binary>"` names the missing binary.

Not available in cloud sessions. `ENABLE_LSP_TOOL=1` appears in older setups;
current docs do not require it.

## Cursor

Cursor is built on VS Code, so its agent uses the language support the editor
already has: built-in features plus the language extensions you install.
There is no separate plugin step. Install these per language:

| Language | What to install | Source |
|----------|-----------------|--------|
| TS / JS | Nothing extra: VS Code includes TypeScript language support (IntelliSense, errors, go to definition, find references). Install `typescript` in the project for `tsc`. Add the ESLint extension for linting. | VS Code TypeScript docs |
| Python | Python (Microsoft), Cursor Pyright, Python Debugger, Ruff | Cursor's Python guide |
| Swift | Swift Language Support (`chrisatwindsurf.swift-vscode`), not Apple's `swiftlang.swift-vscode`. Optional: Sweetpad plus `brew install xcode-build-server` for build/run and fuller navigation. Xcode is still required. | Cursor's Swift guide; Cursor forum staff answer |
| Kotlin | Java and Kotlin by IntelliJ IDEA (`JetBrains.intellij-server`, Open VSX). It is in preview: free for 30-day builds now, an IntelliJ IDEA Ultimate subscription after preview. JetBrains says pure Kotlin projects can use the free, open-source Kotlin LSP instead. | JetBrains docs and blog |

## Steer the agent

Add a line under Tooling in `~/.agents/instructions/shared.md`:

```
- LSP is enabled. Prefer go-to-definition / find-references over grep when
  looking up symbols in code.
```

Without it the agent often defaults to grep.

## Sources

- https://code.claude.com/docs/en/plugins/code-intelligence.md
- https://code.claude.com/docs/en/tools-reference.md (LSP tool behavior)
- https://code.visualstudio.com/docs/languages/typescript
- https://cursor.com/for/python
- https://cursor.com/for/ios-macos-swift
- https://forum.cursor.com/t/i-encounter-an-error-from-the-swift-extension-when-opening-an-xcode-project/146102/2
- https://www.jetbrains.com/help/intellij-vscode/get_started_cursor.html
- https://blog.jetbrains.com/idea/2026/08/intellij-idea-goes-lsp/
