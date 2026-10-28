# AGENTS.md

This file provides guidance to AI agents working in this repository.

## Purpose

Documentation-only repository containing coding conventions and collaboration guidelines, shared across projects. It holds no application and no library, and has no build system: the files are Markdown, a shared editor config, and small scripts that enforce the conventions as plugin hooks. Each script has a test under `tests/hooks/`, run with `bash tests/hooks/<script>-test.sh`. The conventions are the human-readable source of truth and must remain understandable without any AI tooling.

## Structure

```
README.md                              # Index linking to all documents
collaboration/
  git-and-collaboration.md             # Conventional Commits, branching, PR etiquette, ADRs
  code-review-comments.md              # Emoji legend for review comments, and the protocol for answering them
  code-review-triage.md                # Severity/impact/complexity grid, fix-here vs follow-up vs no-action
  issue-labels.md                      # The triage scores carried on every ticket as labels
  code-review-loop.md                  # Review → triage → fix rounds until a review leaves nothing to fix, and the status label
  pull-request-descriptions.md         # Keeping a PR title and description true to its diff as the branch moves
  project-audit.md                     # Project health audit: scope, axes, audit severities, A–E state and effort grids
conventions/
  coding-conventions.md                # Clean Code principles (all languages)
  docs-conventions.md                  # Documentation file naming, section separators, line wrapping, punctuation, Markdown tables
  kotlin-conventions.md                # Kotlin style, idioms, testing, multiplatform (any Kotlin project)
  compose-conventions.md               # Compose UI layer: MVVM, composables, resources
  compose-viewmodel-conventions.md     # Compose ViewModels: naming, state shape, events, lifecycle-aware refresh
  compose-testing-conventions.md       # Compose testing: ViewModel tests, Maestro end-to-end flows
  desktop-distribution-conventions.md  # Shipping a Compose Desktop app: single instance, packaging, releases, signing
  rust-conventions.md                  # Rust backend conventions
  go-conventions.md                    # Go backend conventions
  bruno-conventions.md                 # Bruno API testing conventions
configs/
  .editorconfig                        # Shared editor settings for every file, plus the ktlint configuration for Kotlin
templates/
  adr-template.md                      # Architecture Decision Record skeleton, copied into a project's docs/adr/
  prd-template.md                      # Product Requirement Document skeleton, copied into a project's docs/prd/
.github/
  pull_request_template.md             # PR description template, copied into other projects
.claude-plugin/
  marketplace.json                     # Claude Code marketplace registry (cyrillrx-conventions)
plugins/                               # Derived plugin skills (regenerate with /sync-plugins)
  git-workflow/                        # /commit, /pull-request, /triage-findings, /address-review, /review-loop
  kotlin-conventions/                  # SessionStart hook pointing to a copy of conventions/kotlin-conventions.md
  compose-conventions/                 # SessionStart hook pointing to copies of the three conventions/compose-*.md, by what is written, and of desktop-distribution-conventions.md for a Desktop target
  coding-conventions/                  # SessionStart hook injecting a copy of conventions/coding-conventions.md; PostToolUse hooks recalling §4 when an edit adds comments and pointing to a copy of docs-conventions.md on Markdown edits
  project-health/                      # /audit: graded project health report written to docs/audit-YYYY-MM-DD.md
tests/hooks/                           # One test script per plugin hook script
.claude/skills/
  sync-plugins/                        # Repo-local meta-skill: regenerate plugins from docs
```

## Conventions are the source of truth; plugins are derived

The Markdown docs in `collaboration/` and `conventions/` are the human-readable source of truth and must stay understandable without any AI tooling. The Claude Code plugin skills under `plugins/` are **derived** from those docs.

**When you change a convention doc, regenerate the affected plugin skills in the same PR** by running the repo-local `/sync-plugins` skill. Never hand-edit the generated convention content inside a `SKILL.md`: edit the doc, then sync. Each derived `SKILL.md` names its source doc in a header comment.

## Commit message format

All commits follow **Conventional Commits** (see [`collaboration/git-and-collaboration.md`](collaboration/git-and-collaboration.md)):

```
<type>(<scope>): <subject>

<body>
```

**Types:** `feat`, `fix`, `ui`, `refactor`, `perf`, `style`, `docs`, `test`, `chore`, `ci`, `build`. Subject in the imperative, present tense, no leading capital, no trailing dot.

**Language:** English for commit messages, and for Pull Request titles and descriptions.

Use `git mv` for any file rename or move, to preserve history.

**Authorship:** commits and PRs are owned by their human author. Never add AI attribution: no `Co-Authored-By` trailer, no `🤖 Generated with` footer, no "assisted by" mention. See [`collaboration/git-and-collaboration.md`](collaboration/git-and-collaboration.md#6-authorship).

## Conventions in force

### Collaboration (`collaboration/`)
- PRs: ≤200 lines, ≤10 files; exceptions for mechanical changes
- PR descriptions: the Description is the problem then what changes, about three short sentences' worth, one idea per sentence or bullet; other sections are one short line per item, and nothing restates the diff
- Reviewers must be constructive and back comments with sources
- Trunk-based development; short-lived feature branches named after commit types
- Use [code-review-comments.md](collaboration/code-review-comments.md) to signal blocking vs. non-blocking comments; every comment gets a reply, and a request with no stated reason is discussed, never dismissed
- Every review finding gets a decision (see [code-review-triage.md](collaboration/code-review-triage.md)): severity, impact, complexity, then fix here / follow-up ticket / no action, with its rationale
- Every ticket carries one `severity:*`, one `impact:*` and one `complexity:*` label on the triage scales (see [issue-labels.md](collaboration/issue-labels.md)); no type label, the title prefix carries it
- Iterate review rounds per [code-review-loop.md](collaboration/code-review-loop.md): open comments first, a fresh review each round of correctness and of conformance to the conventions in force, one push at the end, stop when a round has no ✅, or when the author makes a round the last (approving a round's plan runs the next one); when the trend turns or at the cap (10 by default), the plan comes with a diagnosis of why the loop does not converge, and the same approval decides: it goes on when the trend turns, and closes the loop at the cap unless the author extends it
- Project audits follow [project-audit.md](collaboration/project-audit.md): one cause per finding with a stable ID, A–E state and effort grades per module and axis, a verdict from the worst cell and never an average; changing the grading bumps the grid version

### Documentation (`conventions/docs-conventions.md`)
- Doc files use `lowercase-with-hyphens.md`; a name imposed by tooling keeps it (`README.md`, `AGENTS.md`, `CLAUDE.md`, `SKILL.md`, `pull_request_template.md`)
- Sections are separated by the heading itself, no `---` horizontal rule between sections
- Exception: `---` that carries meaning stays (YAML front matter, document separators inside code fences)
- No hard wrap in prose: one line per paragraph, per bullet; column limits apply to code only
- Table pipes align in display columns as Python `wcwidth`'s `wcswidth()` (and Prettier 3) measures them: `W`/`F` characters count 2, `U+FE0F` widens the one before it to 2, so `⚠️` = 2 but `⛏` and `🏕` = 1
- Table columns are at least 3 columns wide (a formatting choice); a column whose widest cell exceeds 120 columns, and every column to its right, is left unpadded
- ADRs and PRDs start from the skeletons in `templates/`; numbers are never reused, and a superseded document keeps its file

### Kotlin / Compose (`conventions/kotlin-conventions.md`, `conventions/compose-*.md`)
- Kotlin only; Jetpack/Compose Multiplatform, no XML layouts, no View-system APIs
- MVVM + Unidirectional Data Flow: `StateFlow` for state, `SharedFlow` (one-shot) for events
- Formatting 100% delegated to ktlint via `configs/.editorconfig` (4-space indent, 120 cols, trailing commas)
- Prefer early returns over deep nesting; prefer affirmative conditions
- Image resources: `ic_` prefix + size suffix for icons, `img_` prefix + size suffix for multicolor images

### Desktop distribution (`conventions/desktop-distribution-conventions.md`)
- One instance per user: an OS file lock on `instance.lock` in the application data directory, taken before anything else touches it; a second launch activates the first through a Unix domain socket and exits, never runs degraded
- Application data in the per-OS user data directory, never the temp directory
- Release `nativeDistributions` settings: user-visible `packageName`, `bundleID`, a fixed `upgradeUuid`, per-user MSI install, a Start menu entry, icons, `modules(...)` checked with `suggestRuntimeModules`, ProGuard checked with `runReleaseDistributable`
- Version from the `vMAJOR.MINOR.PATCH` tag, within the MSI and DMG limits; installers built by a tag-triggered release workflow, one runner per OS, separate from CI
- Unsigned installers and manual updates by default; signing and automatic updates are per-project ADR decisions

### Backend (`conventions/{rust,go}-conventions.md`)
- Layered architecture, explicit error handling, formatter-enforced style (`rustfmt` / `gofmt`)
