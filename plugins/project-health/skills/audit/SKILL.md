---
name: audit
description: >-
  Audit a project's health: grade each module and the repository from A to E on state and on
  effort, list blockers, bugs, debt and obsolescence, gaps to the conventions and consumer needs,
  and estimate the workload. Writes docs/audit-YYYY-MM-DD.md and changes nothing else. Run manually
  before resuming or realigning a project.
argument-hint: "[consumer-project ...]"
disable-model-invocation: true
# Read-only on the audited project. Write is left out on purpose: the report is the one write,
# and its prompt is the check that nothing else gets written. Building, running the tests and any
# forge call are prompted too, and so are git grep, git log and git show: their -O and --output
# options run a command or write a file, so they are never pre-approved. Subagents do not inherit this list: they run as this plugin's
# auditor agent, which has no Edit or Write tool, and keeps Bash for git, under the session's own
# permissions.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - WebSearch
  - WebFetch
  - Bash(git status:*)
  - Bash(git cat-file -p:*)
  - Bash(git ls-tree:*)
  - Bash(git rev-parse:*)
  - Bash(git ls-files:*)
  - Bash(git branch --show-current)
  - Bash(git log -1 --format=%cs refs/remotes/origin/HEAD)
  - Bash(git symbolic-ref --short refs/remotes/origin/HEAD)
---

<!--
The scope rules, axes, severities, grids and verdict in this skill are derived from
collaboration/project-audit.md in cyrillrx/coding-conventions (Grid v1), and the obsolescence
reference from the "latest stable" lines of conventions/*-conventions.md. Keep them in sync with
/sync-plugins.
-->

## Context

- Default branch, as its remote-tracking ref: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo "unresolved — ask"`
- Audited revision (tip of the default branch, as last fetched): !`git rev-parse --short refs/remotes/origin/HEAD 2>/dev/null || echo "unresolved — ask"`
- Date of that revision: !`git log -1 --format=%cs refs/remotes/origin/HEAD 2>/dev/null || echo "unresolved"`
- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`
- Build files at that revision: !`git ls-tree -r --name-only refs/remotes/origin/HEAD 2>/dev/null | grep -E '(^|/)(settings\.gradle\.kts|build\.gradle\.kts|Cargo\.toml|go\.mod|bruno\.json)$' || echo "none"`
- Previous audits at that revision: !`git ls-tree -r --name-only refs/remotes/origin/HEAD docs/ 2>/dev/null | grep -E '^docs/audit-.*\.md$' || echo "none"`
- Previous audits in the working tree, committed or not: !`git ls-files --cached --others --exclude-standard 'docs/audit-*.md' 2>/dev/null | grep . || echo "none"`
- Consumer projects given: $ARGUMENTS

## Your task

Audit the project in the current directory and write the result to `docs/audit-YYYY-MM-DD.md`, for today. The audit is **read-only**: the report is the only file you write, and you never commit it. The grading below is **Grid v1** of the [Project Audit](https://github.com/cyrillrx/coding-conventions/blob/main/collaboration/project-audit.md) guide; apply it exactly, so that two audits of the same project compare.

### Step 0 — Pin the revision

The audit reads **one pinned commit**: the tip of the default branch above, `<sha>`. Every file is read at that commit — `git cat-file -p <sha>:<path>`, `git ls-tree -r <sha>` — never from the working tree, which may sit on another branch or change while the audit runs. If the default branch reads "unresolved", ask the user to run `git remote set-head origin --auto`, or to name the branch to audit. If the remote-tracking branch looks stale, ask the user to fetch first; never check out, stash, fetch or reset anything yourself. `git grep <pattern> <sha>` and `git log <sha>` work at the pinned commit too, but each call is prompted: read files with `git cat-file -p`, never with `git show`.

### Step 1 — Frame the scope, and confirm it

- **Modules.** A module is one build unit: a Gradle module (from `settings.gradle.kts`), a Cargo workspace member, a Go module (`go.mod`), or a Bruno collection (`bruno.json`). A single-module project has one module row.
- **Default rules:**

| Path                                                           | Treatment                                                      |
|----------------------------------------------------------------|----------------------------------------------------------------|
| Generated or vendored code (`build/`, `generated/`, `vendor/`) | Excluded; listed in the scope so the exclusion is visible      |
| Build logic (`buildSrc/`, `build-logic/`)                      | Not a module; graded under the repository row, as Build and CI |
| Sample or demo apps (`sample/`, `demo/`)                       | Graded on Security and on Dependencies and obsolescence only   |
| Dedicated test modules                                         | Attached to the module they test                               |

- **Per-stack checklists.** When `checklists/<stack>.md` exists next to this skill, hand it to the subagents with the common base. None ships yet: they will be derived from `conventions/<stack>-conventions.md` through `/sync-plugins`. Until then, the subagents read that convention doc from GitHub directly, and the report says the stack checklist was not applied. A Kotlin module reads `kotlin-conventions.md`, and `compose-conventions.md` as well when it uses Compose.
- **Consumers.** The consumer projects are the arguments, as local paths or `owner/repo`. Without any, the Consumers section reads "Not assessed: no consumer project was given". Never search for consumers, never guess them.
- **Previous audit.** When a `docs/audit-*.md` exists, at the pinned revision or in the working tree, read the latest one by date: its finding IDs, its grades and its grid version feed Step 3. A report that was never pushed still counts, or its IDs would be reused. Previous reports are the one exception to the pinned commit: they are the audit's history, not the audited code.

Then **always** show the scope — each module included, excluded or attached, with its reason — and the cost: five subagents each read a large part of the repository. Say that the subagents do not inherit this skill's permissions, so each of their `git cat-file -p` and `git ls-tree` calls is prompted, hundreds on a medium project, and denied outright in a mode that cannot prompt. Offer the one-time fix: add `Bash(git cat-file -p:*)` and `Bash(git ls-tree:*)` to `permissions.allow` in the project's or the user's Claude Code settings. Wait for the user to confirm or adjust it. A module they leave out is graded `—`, "not assessed".

### Step 2 — Fan out, five subagents

Launch the five subagents below in parallel, each with the `project-health:auditor` type: it reads whole files rather than excerpts, and cannot edit. Never use `Explore` here — it locates code, it does not review it. Ask each for a very thorough pass over the whole scope. Each one receives the project root, the confirmed scope, the detected stacks, its checklist below, any per-stack checklist, and these rules:

- Read only. Do not edit, build, run tests, or install anything.
- Read every file at the pinned commit with `git cat-file -p <sha>:<path>`, never from the working tree.
- Return findings, not prose. **One fix is one finding**, listing all its occurrences. Each finding has: the module it belongs to (or "repository"), its axis, a proposed severity from the table in Step 3, its evidence (`file:line`, or a cited source), and _likely_ when only a build or a run would confirm it — together with any existing evidence that settles it, such as a build report or a CI log.
- Every claim is checked in the repository. Never report a finding inferred from a file name alone.

| Subagent                 | Axes                               | Checklist |
|--------------------------|------------------------------------|-----|
| Code and architecture    | Code, Architecture                 | Bugs and broken contracts, thread safety, error handling, dead code, public API consistency. Layering, coupling, dependencies between modules, the architecture the stack's convention doc prescribes. |
| Tests                    | Tests                              | Which tests exist, whether they run at all, what they cover and miss, critical logic left untested, order dependence, assertion-free tests. |
| Security                 | Security                           | Secrets in the tree and in the history, unsafe input handling, dependencies with known vulnerabilities, CI permissions and secrets handling. |
| Build, CI and docs       | Build and CI, Docs and conventions | Build configuration and its deprecations, targets, publishing and signing, CI workflows and what they check, release process. README and module docs, doc comments, stale files, git history against Conventional Commits, ADRs, formatter config, against [coding-conventions](https://github.com/cyrillrx/coding-conventions) and the stack's convention doc. |
| Dependencies and context | Dependencies and obsolescence      | Every toolchain and dependency version against its latest stable release, with the release page as source. Deprecated, end-of-life or abandoned SDKs. Each consumer given: targets, toolchain, what it would need. Gaps to the market's reference libraries. |

Only the dependencies and context subagent searches the web; every subagent may fetch the `cyrillrx/coding-conventions` docs it needs. The dependencies subagent's obsolescence reference is the "latest stable" line of each stack's convention doc — [Kotlin](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/kotlin-conventions.md), [Go](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/go-conventions.md), [Rust](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/rust-conventions.md). The security and the build, CI and docs subagents may read the forge's repository settings with read-only `gh api` calls — alerts, rulesets, branch protection — and mark those facts as today's state, not the commit's. Market gaps and consumer needs are **reported, not graded**: each market comparison cites its source and carries a "verify" marker.

### Step 3 — Identify and grade

Collect the findings and merge them: **one fix is one finding**, so the same problem reported by several subagents becomes one finding, and two problems closed by one change become one. File each finding **where its fix is made**: its axis is the one the fix belongs to, whichever subagent revealed it; its module is the one the fix touches, and a fix spanning several modules is filed under each, with the same ID; a build problem specific to one module goes on the repository row, under Build and CI, tagged with that module.

**Set every severity yourself** against the table below and its examples: the subagent's severity is a proposal. **Settle the _likely_ findings** with any evidence already at hand, such as a build report or a CI log, in either direction.

Give each finding a stable ID, `<AXIS>-NN` — `CODE`, `ARCH`, `TEST`, `DEPS`, `SEC`, `BUILD`, `DOCS`: a finding that matches one of the previous audit keeps its ID; a new one numbers on from the previous report's **Last IDs** line on its axis — or, when that report has none, from the highest ID it mentions — and never from a gap; a fixed ID is never reused.

Severities, read for a project at rest:

| Level          | Meaning in an audit                                                                         | Examples |
|----------------|---------------------------------------------------------------------------------------------|-----|
| 🔴 **Blocker** | Breaks what already exists: the module cannot be used, built or released as it ships today. | Crash on the main path; exploitable security hole; build broken on the latest stable toolchain; data loss; a release pipeline that publishes broken artifacts. |
| 🟠 **Major**   | Wrong behavior, a broken promise, or a missing piece the project's purpose depends on.      | Wrong result in an edge case; broken public contract; untested critical logic; end-of-life dependency; a deprecation that breaks on the next toolchain upgrade; a library never published because no release process exists yet; an accepted ADR not implemented. |
| 🟡 **Minor**   | A maintainability or convention gap, with no behavior change.                               | Duplication; missing doc or KDoc; a test without assertion; a dependency behind its latest stable release but still supported; a convention rule not followed. |
| 🔵 **Nit**     | Cosmetics. Listed, never counted.                                                           | Stale comment; dead helper; naming inconsistency inside a private scope. |

A missing first release is 🟠, not 🔴: 🔴 is reserved for breaking what already ships.

The cells are the modules × Code, Architecture, Tests, Dependencies and obsolescence, Security, plus the repository × Security, Build and CI, Docs and conventions. A cell that does not apply reads `·`; one that could not be assessed reads `—` with the reason.

**State grade.** Count the 🔴, 🟠 and 🟡 filed under each cell — a _likely_ finding counts like a confirmed one — and read the grid from E upwards; the first line that holds is the grade:

| Grade | Holds when                         |
|-------|------------------------------------|
| E     | At least one 🔴                    |
| D     | Three 🟠 or more                   |
| C     | One or two 🟠, or more than ten 🟡 |
| B     | Four to ten 🟡                     |
| A     | Three 🟡 or fewer                  |

**Effort.** Effort is measured in person-days: one focused working day of one person, about six effective hours. Group the findings into **narrow** work items — one cell each where possible; split a cross-cutting change into the items each cell needs — and size each one on the audit's scale below, never on the triage complexity scale, which sizes a change about to merge. The estimate covers the test and the verification. Fixes of a few minutes each in the same cell form **one** item: ten ten-minute fixes are one S, not ten.

| Size  | Estimated effort                 | Counts as                                                         |
|-------|----------------------------------|-------------------------------------------------------------------|
| **S** | Up to about two hours            | 0.25 person-day                                                   |
| **M** | More than two hours, up to a day | 1 person-day                                                      |
| **L** | More than a day                  | The person-days its estimate states — an L item always states one |

An item that still improves several cells counts in full in each; the total effort counts it once. Each cell shows its person-days and the matching grade, such as `3.75 (C)`:

| Grade | Effort of the cell        |
|-------|---------------------------|
| A     | Under 1 person-day        |
| B     | 1 to under 3 person-days  |
| C     | 3 to under 7 person-days  |
| D     | 7 to under 15 person-days |
| E     | 15 person-days or more    |

**Verdict.** Never average. **Blocked** when a cell's state is E, **Needs work** when one is C or D, **Healthy** when all are A or B — read on the assessed cells only, and marked **partial**, naming the `—` cells, when any cell is not assessed — followed by the total effort in person-days.

**Progress.** With a previous audit, put both grade tables side by side, then list the IDs fixed, still open and new. If the previous audit used another grid version, recompute its grades with Grid v1 from its findings first. If it has no grid, or its findings name no module, mark its grades not comparable and compare its findings only: fixed, still open, or corrected.

**Confirm the blockers.** If a 🔴 is still _likely_, it alone decides the verdict: before writing, offer to confirm it with the one build or run it needs — prompted — and grade with the outcome.

### Step 4 — Write the report

The default branch is the remote-tracking ref above without its `origin/` prefix: `origin/main` is `main`. When the current branch is not the default branch, or there are uncommitted changes, ask the user where to write the report rather than adding it to unrelated work. Otherwise write `docs/audit-YYYY-MM-DD.md` from the template below, in English, following the [documentation conventions](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/docs-conventions.md): no hard wrap, no `---` between sections, aligned tables. Delete the HTML comments and any section that does not apply, except Consumers, which says "Not assessed" instead. If the file already exists, ask before overwriting it.

```markdown
# Project Audit — YYYY-MM-DD

> **Audited revision**: `<sha>` (<date>) on `<default branch>` | **Grid**: v1 | **Method**: static read, compared with `cyrillrx/coding-conventions`, <the consumers given> and the latest stable toolchain. <"Nothing was built; findings marked _likely_ need a build to confirm.", or the commands run.>

<!-- One paragraph: what the project is, where it was left, what it must serve now. Then the confirmed scope: modules graded, excluded or attached, with the reason. -->

## State

| Module     | Code | Architecture | Tests | Dependencies | Security | Build and CI | Docs and conventions |
|------------|------|--------------|-------|--------------|----------|--------------|----------------------|
| <module>   |      |              |       |              |          | ·            | ·                    |
| Repository | ·    | ·            | ·     | ·            |          |              |                      |

## Effort

<!-- Same shape as State; each cell reads `<person-days> (<grade>)`, such as `3.75 (C)`. -->

**Verdict**: <Blocked | Needs work | Healthy><, partial — not assessed: <the `—` cells>> — <the cells that drive it>. Total effort: <N> person-days.

**Last IDs**: <`CODE-NN`, `ARCH-NN`, … — the highest ID ever used on each axis, fixed ones included; `—` for an axis never used>.

## Progress since the last audit

<!-- Only with a previous audit: both grade tables side by side, then the IDs fixed, still open, and new. -->

## Blockers

## Bugs

## Debt and obsolescence

| ID | Item | Found | Latest stable | Source |
|----|------|-------|---------------|--------|

## Quality and tests

<!-- As needed: architecture, public API, tests, documentation, security. Each finding with its ID, severity, module and evidence. Nits are listed here too, marked 🔵. -->

## Gaps to `cyrillrx/coding-conventions`

| ID | Rule | State |
|----|------|-------|

## Market

<!-- Reported, not graded. Each comparison cites its source and is marked "verify". -->

## Consumers

<!-- Reported, not graded. -->

## Workload estimate

| Work item | IDs it closes | Cells it improves | Size | Person-days |
|-----------|---------------|-------------------|------|-------------|
```

### Step 5 — Hand over

Summarise the verdict, the worst cells and the total effort in a few lines, and point to the report. Then offer, without doing any of it unasked:

- to confirm the remaining _likely_ findings by running the build and the tests — each command is prompted, and the report is updated with the outcome;
- to commit the report with `/git-workflow:commit`;
- to draft an action plan from the work items.

## Rules

- The report is the only write. No fix, no commit, no branch, no ticket, no checkout, no fetch.
- The scope is always confirmed before the fan-out.
- Static by default: nothing is built or run without the user's consent.
- Every file is read at the pinned commit, never from the working tree — previous audit reports excepted.
- One fix is one finding, filed where its fix is made, with a stable ID and its evidence. You set the severity.
- Consumers are given, never guessed. Market gaps and consumer needs are reported, never graded.
- Grades follow Grid v1 exactly; the verdict follows the worst cell, never a mean.
