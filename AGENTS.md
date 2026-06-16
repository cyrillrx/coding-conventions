# AGENTS.md

This file provides guidance to AI agents working in this repository.

## Purpose

Documentation-only repository containing coding conventions and collaboration guidelines, shared across projects. There is no build system, no tests, and no runnable code — all files are Markdown (plus a shared editor config). The conventions are the human-readable source of truth and must remain understandable without any AI tooling.

## Structure

```
README.md                              # Index linking to all documents
collaboration/
  git-and-collaboration.md             # Conventional Commits, branching, PR etiquette, ADRs
  code-review-emojis.md                # Emoji legend for code review comments
conventions/
  coding-conventions.md                # Clean Code principles (all languages)
  docs-conventions.md                  # Documentation file naming, Markdown tables
  kmp-conventions.md                   # Kotlin Multiplatform / Compose style, architecture, testing
  rust-conventions.md                  # Rust backend conventions
  go-conventions.md                    # Go backend conventions
  bruno-conventions.md                 # Bruno API testing conventions
configs/
  kotlin/.editorconfig                 # Shared ktlint configuration for Kotlin projects
.claude-plugin/
  marketplace.json                     # Claude Code marketplace registry (cyrillrx-conventions)
plugins/                               # Derived plugin skills (regenerate with /sync-plugins)
  git-workflow/                        # /commit, /address-review
  kmp-conventions/                     # kmp-style knowledge skill
.claude/skills/
  sync-plugins/                        # Repo-local meta-skill: regenerate plugins from docs
```

## Conventions are the source of truth; plugins are derived

The Markdown docs in `collaboration/` and `conventions/` are the human-readable source of truth and must stay understandable without any AI tooling. The Claude Code plugin skills under `plugins/` are **derived** from those docs.

**When you change a convention doc, regenerate the affected plugin skills in the same PR** by running the repo-local `/sync-plugins` skill. Never hand-edit the generated convention content inside a `SKILL.md` — edit the doc, then sync. Each derived `SKILL.md` names its source doc in a header comment.

## Commit message format

All commits follow **Conventional Commits** (see [`collaboration/git-and-collaboration.md`](collaboration/git-and-collaboration.md)):

```
<type>(<scope>): <subject>

<body>
```

**Types:** `feat`, `fix`, `ui`, `refactor`, `perf`, `style`, `docs`, `test`, `chore`, `ci`, `build`. Subject in the imperative, present tense, no leading capital, no trailing dot.

Use `git mv` for any file rename or move, to preserve history.

**Authorship:** commits and PRs are owned by their human author. Never add AI attribution — no `Co-Authored-By` trailer, no `🤖 Generated with` footer, no "assisted by" mention. See [`collaboration/git-and-collaboration.md`](collaboration/git-and-collaboration.md#6-authorship).

## Conventions in force

### Collaboration (`collaboration/`)
- PRs: ≤200 lines, ≤10 files; exceptions for mechanical changes
- Reviewers must be constructive and back comments with sources
- Trunk-based development; short-lived feature branches named after commit types
- Use [code-review-emojis.md](collaboration/code-review-emojis.md) to signal blocking vs. non-blocking comments

### Kotlin / Compose (`conventions/kmp-conventions.md`)
- Kotlin only; Jetpack/Compose Multiplatform — no XML layouts, no View-system APIs
- MVVM + Unidirectional Data Flow: `StateFlow` for state, `SharedFlow` (one-shot) for events
- Formatting 100% delegated to ktlint via `configs/kotlin/.editorconfig` (4-space indent, 120 cols, trailing commas)
- Prefer early returns over deep nesting; prefer affirmative conditions
- Image resources: `ic_` prefix + size suffix for icons, `img_` prefix + size suffix for multicolor images

### Backend (`conventions/{rust,go}-conventions.md`)
- Layered architecture, explicit error handling, formatter-enforced style (`rustfmt` / `gofmt`)
