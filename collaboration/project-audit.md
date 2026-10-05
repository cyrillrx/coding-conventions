# Project Audit

An audit measures the health of a whole project at rest: what risks it carries today, and what it costs to bring it back to a good state. This document defines how an audit is scoped, how its findings are counted, and how they become grades, so that two audits of the same project, months apart, can be compared.

The grades follow a project **over time**. They are not built to rank two projects against each other, and they do not decide on their own whether a project is resumed or archived — that decision belongs to its owner, with the report in hand.

The current grading is **Grid v1**. Every report states the grid version it was graded with.

## 1. Scope

An audit reads **one pinned commit**: the tip of the project's default branch. Every file is read at that commit, never from the working tree, which may sit on another branch or change while the audit runs. Facts that only exist outside the history, such as the forge's repository settings, are read as they are today and marked so.

The unit of grading is the **module**, meaning one build unit: a Gradle module, a Cargo workspace member, a Go module (`go.mod`), or a Bruno collection (`bruno.json`). A single-module project has one module row.

Default rules decide what is graded:

| Path                                                           | Treatment                                                      |
|----------------------------------------------------------------|----------------------------------------------------------------|
| Generated or vendored code (`build/`, `generated/`, `vendor/`) | Excluded; listed in the scope so the exclusion is visible      |
| Build logic (`buildSrc/`, `build-logic/`)                      | Not a module; graded under the repository row, as Build and CI |
| Sample or demo apps (`sample/`, `demo/`)                       | Graded on Security and on Dependencies and obsolescence only   |
| Dedicated test modules                                         | Attached to the module they test                               |

The scope — modules included, excluded or attached, each with its reason — is always shown to the person running the audit and confirmed before the audit starts. They may adjust it; a module they leave out is reported as not assessed.

## 2. Axes

Seven axes are graded. Most are graded per module; the ones that belong to the repository as a whole are graded once, on a **repository** row.

| Axis                          | Graded on                                                                             |
|-------------------------------|---------------------------------------------------------------------------------------|
| Code                          | Each module                                                                           |
| Architecture                  | Each module                                                                           |
| Tests                         | Each module                                                                           |
| Dependencies and obsolescence | Each module                                                                           |
| Security                      | Each module (code, vulnerable dependencies) and the repository (secrets, CI, history) |
| Build and CI                  | The repository                                                                        |
| Docs and conventions          | The repository                                                                        |

A cell that does not apply reads `·`. A cell that applies but could not be assessed reads `—`, with the reason.

Gaps to the market's reference libraries and the needs of consumer projects are **reported, not graded**. They are opportunities rather than defects, and they rest on external sources that need verifying. They appear in the report and in the workload estimate, never in a state grade.

The obsolescence reference is the "latest stable" line of each stack's convention doc, such as [Kotlin](../conventions/kotlin-conventions.md), [Go](../conventions/go-conventions.md) or [Rust](../conventions/rust-conventions.md).

## 3. Findings

- **One fix is one finding.** A finding is defined by the change that would close it: the same problem repeated in twelve files is a single finding listing its twelve occurrences, and two problems closed by one change are one finding. Two changes that could ship separately are two findings. Counting fixes rather than symptoms keeps the grades stable from one audit to the next.
- **A finding sits where its fix is made.** Its axis is the one the fix belongs to, whichever angle revealed it: a deprecated dependency found while checking security is a Dependencies finding. Its module is the one the fix touches; a fix spanning several modules is filed under each of them, with the same ID. A build problem specific to one module goes on the repository row, under Build and CI, tagged with that module.
- **Every finding has a stable ID**, `<AXIS>-NN` — `CODE`, `ARCH`, `TEST`, `DEPS`, `SEC`, `BUILD`, `DOCS`. An ID carries over from one audit to the next while the finding stands, and is never reused once it is fixed. Since a report only lists the IDs fixed since the previous one, every report also records the **last ID used** on each axis, and a new finding numbers on from there — never from the IDs a report happens to list.
- **Every finding carries its evidence**: a `file:line`, or a cited source.
- **Severity is set once, against §4**, by whoever grades the audit, not by whoever found the problem. Two readers who disagree settle it on the definition and its examples.
- A finding that only a build or a run would confirm is marked _likely_, and counts like a confirmed one. Before grading, any evidence already at hand — a build report, a CI log — settles it either way. A 🔴 still _likely_ after that is offered for confirmation before the report is written, since it alone decides the verdict.

## 4. Severity

The levels and their emojis are those of [Code Review Triage](code-review-triage.md#2-severity), read for a project at rest rather than for a change about to merge:

| Level          | Meaning in an audit                                                                         | Examples |
|----------------|---------------------------------------------------------------------------------------------|-----|
| 🔴 **Blocker** | Breaks what already exists: the module cannot be used, built or released as it ships today. | Crash on the main path; exploitable security hole; build broken on the latest stable toolchain; data loss; a release pipeline that publishes broken artifacts. |
| 🟠 **Major**   | Wrong behavior, a broken promise, or a missing piece the project's purpose depends on.      | Wrong result in an edge case; broken public contract; untested critical logic; end-of-life dependency; a deprecation that breaks on the next toolchain upgrade; a library never published because no release process exists yet; an accepted ADR not implemented. |
| 🟡 **Minor**   | A maintainability or convention gap, with no behavior change.                               | Duplication; missing doc or KDoc; a test without assertion; a dependency behind its latest stable release but still supported; a convention rule not followed. |
| 🔵 **Nit**     | Cosmetics. Listed, never counted.                                                           | Stale comment; dead helper; naming inconsistency inside a private scope. |

A missing first release is 🟠, not 🔴: 🔴 is reserved for breaking what already ships.

## 5. State grade

Each cell gets a state grade from the findings filed under it: the worst severity sets a ceiling, and the volume lowers the grade below it. Read the grid from E upwards — the first line that holds is the grade.

| Grade | Holds when                         |
|-------|------------------------------------|
| E     | At least one 🔴                    |
| D     | Three 🟠 or more                   |
| C     | One or two 🟠, or more than ten 🟡 |
| B     | Four to ten 🟡                     |
| A     | Three 🟡 or fewer                  |

A single 🔴 is enough for an E: the module cannot be used or released as it stands.

Examples: no finding → A; eleven 🟡 → C; one 🟠 and no 🟡 → C; three 🟠 → D; one 🔴 → E.

## 6. Effort and workload

Effort is measured in **person-days**: one person-day is one focused working day of one person, about six effective hours, whenever it is actually done.

The findings are grouped into **work items**, and each item is sized S, M or L on the audit's own scale below. It is not the [triage complexity scale](code-review-triage.md#4-complexity-to-address): that one sizes a change about to merge, this one sizes work on a project at rest. The estimate covers the test and the verification, not just the edit.

| Size  | Estimated effort                 | Counts as                                                         |
|-------|----------------------------------|-------------------------------------------------------------------|
| **S** | Up to about two hours            | 0.25 person-day                                                   |
| **M** | More than two hours, up to a day | 1 person-day                                                      |
| **L** | More than a day                  | The person-days its estimate states — an L item always states one |

Fixes of a few minutes each in the same cell form **one** item: ten ten-minute fixes are one S, not ten.

Work items are kept **narrow**: an item should improve one cell where it can. A cross-cutting change is split into the items each cell needs — a redesign that also enables API validation and writes the KDoc becomes three items, filed under Code, Build and CI, and Docs. An item that still improves several cells counts in full in each of them; the total effort counts each item once.

Each cell shows its effort in person-days, followed by the matching grade, such as `3.75 (C)`. The grade is only a reading of the number:

| Grade | Effort of the cell        |
|-------|---------------------------|
| A     | Under 1 person-day        |
| B     | 1 to under 3 person-days  |
| C     | 3 to under 7 person-days  |
| D     | 7 to under 15 person-days |
| E     | 15 person-days or more    |

Examples: a cell with three S items → `0.75 (A)`; a cell with one 15-person-day L item → `15 (E)`.

## 7. Verdict

The state grades are never averaged. The verdict follows the worst cell:

- **Blocked** — at least one cell is graded E.
- **Needs work** — at least one cell is graded C or D.
- **Healthy** — every cell is graded A or B.

The verdict is read on the assessed cells only. When any cell reads `—`, the verdict is marked **partial** and names those cells: a module nobody looked at never counts as healthy.

The verdict line also states the total effort, in person-days.

## 8. Following a project over time

- A report is written to `docs/audit-YYYY-MM-DD.md` in the audited project. The previous audit is the latest such file, whether it is already on the default branch or still local: a report that was never pushed still holds IDs that must not be reused, so previous reports are the one thing read outside the pinned commit. When the working tree is not on the default branch, or holds uncommitted changes, the person running the audit chooses where the report goes, so it never lands in unrelated work.
- When a previous audit exists, the report opens with its progress: both grade tables side by side, then the finding IDs fixed, still open, not reassessed, and new. A previous finding whose cell now reads `—`, or whose module was left out of scope, is not reassessed: it keeps its ID and stays open, and is never reported as fixed. New IDs number on from the previous report's last IDs; a report that records none falls back to the highest ID it mentions.
- When the grid version changed since the previous audit, the previous grades are recomputed with the current grid from that report's findings, so the comparison holds.
- A previous audit with no grid, or whose findings name no module, cannot be regraded. Its grades are marked not comparable, and only its findings are compared: fixed, still open, or corrected.
- Changing this document's grading — axes, severities, either grid — bumps the grid version.
