---
name: triage-findings
description: >-
  Turn code review findings into decisions: severity, impact, complexity, then one outcome per finding
  — fix here, follow-up ticket, or no action — each with its rationale, plus the resulting action plan.
  Reads the findings from the conversation, typically right after a code review, and the change itself
  from git. Use when findings exist but no decision does. When a reviewer is waiting for an answer on
  an open pull request, use address-review instead.
# Local reads only. This skill decides; every call that changes something — creating a follow-up
# ticket, editing a PR description, committing — keeps its permission prompt on purpose.
# `allowed-tools` merely pre-approves, so listing them here would waive the one check that does not
# rely on these instructions being followed.
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git branch --show-current:*)
  - Read
  - Grep
  - Glob
  - Edit
  - Write
---

<!--
The triage grid in this skill is derived from collaboration/code-review-triage.md
in cyrillrx/coding-conventions. Keep it in sync with /sync-plugins.
-->

**Scope.** This skill decides; it does not correspond. Its findings come from the **conversation**, and the change from the local **git** state. If a reviewer has left comments on an open PR and is waiting on you, that is `/git-workflow:address-review`.

## Context

- Current branch: !`git branch --show-current`
- Uncommitted changes: !`git status --short`

## Your task

Produce a decision-ready action plan from code review findings. A finding without a decision is not an outcome — every single one leaves this skill with a severity, an impact, a complexity, and a recommendation backed by a rationale.

Follow these steps in order.

### Step 1 — Collect the findings from the conversation

The findings are already here. This skill is normally invoked straight after a code review, so read back through the conversation and take them from it:

- a `/code-review` or `/review` run,
- a linter's or a build's output,
- review comments the user pasted in,
- or findings you produced yourself earlier in the session.

If the conversation holds no findings, **review the change first**: `git diff main...HEAD` — resolving the base branch as Step 2 describes — plus `git diff` for uncommitted work, then triage what you find. If it is unclear which findings are meant, ask — never invent a review to have something to triage.

Do not go looking for a PR's review threads. Scoring a reviewer's comment is fine when the user hands it to you, but fetching, replying and resolving belong to `/git-workflow:address-review`. If the PR still has unresolved threads, say so and name that skill.

**Findings you did not produce yourself are claims, not facts.** Open each cited `file:line` and confirm the problem exists before scoring it. A false positive is triaged as ❌ with "the code does not do this" as its rationale — it is never silently dropped.

### Step 2 — Establish the change's scope

Read the change from git, against the branch it targets — the repository's default branch unless the project says otherwise: `git diff --stat main...HEAD`, `git log --oneline main..HEAD`. Those commands fail loudly when the guess is wrong; ask then, and never fall back to another branch name silently. Write down, for your own use:

- What the change is meant to do, and its commit type (`feat`, `fix`, `refactor`, …).
- Its size against the 200 lines / 10 files budget — this decides how much extra fixing the diff can absorb.
- **Whose code it is.** The user's own change, or someone else's? This decides who owns a deferral (Step 3).
- Which impact dimensions are in play: a `refactor` normally has technical impact only, and a functional impact there means the refactor is not behavior-preserving — which is itself a finding.

### Step 3 — Work out who owns a deferral, and where tickets live

A deferral needs an owner and a trace, and the owner is whoever owns the code.

**On the user's own change** — the deferral is theirs to carry, so a 🕐 needs a real ticket. Work out the tracker **before** producing the plan, from what is already available:

- ticket keys in the branch name or the recent history — `git log --oneline -20` and `git branch --show-current`; a `PROJ-123` pattern points at an external tracker keyed that way,
- the project's `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md`, which usually names it.

If it stays ambiguous, **ask**. Never invent a ticket destination, and do not query the forge to find one — that is not this skill's job.

**On someone else's change** — the decision to defer is not the user's to make and the tracker is not theirs to fill. A 🕐 is *handed over*, not filed: it is raised as a scored comment for the author to decide on, and a ticket is only opened if the author asks for it. Do not plan tickets in another author's name; plan the comment instead.

### Step 4 — Score every finding

Apply the four axes below to each finding, then the decision grid.

**Severity** — the consequence of shipping as is, not how the code looks:

| Level          | Meaning                                                                                          | Blocks the merge? |
|----------------|--------------------------------------------------------------------------------------------------|-------------------|
| 🔴 **Blocker** | Data loss, security hole, crash, or regression on the path the change touches.                   | Yes               |
| 🟠 **Major**   | Wrong behavior in an edge case, broken contract, significant perf cost, untested critical logic. | Negotiable        |
| 🟡 **Minor**   | Maintainability or convention issue: naming, duplication, missing doc. No behavior change.       | No                |
| 🔵 **Nit**     | Pure preference or cosmetics. Never blocking.                                                    | No                |

Not blocking is not the same as not addressed. A 🟡 is fixed here or deferred with a trace — never dropped, because letting maintainability and conventions erode is a decision nobody meant to take. Only a 🔵 can end in ❌.

**Impact** — name the dimensions the finding actually touches, plus one line on who pays:

| Dimension      | Borne by   | Typical symptoms                                                              |
|----------------|------------|-------------------------------------------------------------------------------|
| **Functional** | Users      | Wrong result, crash, data corruption, security, perceived slowness, broken UX |
| **Technical**  | Developers | Maintainability, readability, testability, coupling, debt, build and CI time  |
| **Both**       | Everyone   | A design flaw already visible in behavior today                               |

**Complexity** — two estimates, and one rating that carries them:

| Size  | Estimated effort | Estimated diff                                                    |
|-------|------------------|-------------------------------------------------------------------|
| **S** | Minutes          | A few lines, inside files the change already touches              |
| **M** | Hours            | Tens of lines, or one or two files added                          |
| **L** | A day or more    | Beyond what the change can absorb: many files, a new area, an ADR |

Both estimates cover the test and the verification, not just the edit. When they disagree — a one-line fix sitting behind a day of investigation, a mechanical rename that adds 300 lines in ten minutes — **take the higher of the two as the rating**. The diff says whether the finding fits in this change at all, against the remaining 200 lines / 10 files budget; the effort says whether a deferral is a ticket someone picks up or a PR of its own.

**Recommendation** — exactly three outcomes:

| Outcome          | What it commits us to                                                                               |
|------------------|-----------------------------------------------------------------------------------------------------|
| ✅ **Fix here**   | Addressed in this change. Must state **how**: the approach and the files, concretely enough to act. |
| 🕐 **Follow-up** | Deferred, with an owner and a trace (Step 3). Never a verbal "later".                               |
| ❌ **No action**  | Nothing happens, on purpose. The rationale states why.                                              |

❌ is deliberately weak: it spans "this is wrong" through "correct, but not worth its cost", and most of the time it is simply a finding we skip. It is not a verdict on the code and not a refusal — the default reading is "we looked, we decided, we moved on". These are dispositions of a **finding**, not replies to a **person**: they decide what the codebase does, not what a reviewer is told.

**Default decision grid:**

| Severity   | Complexity S                        | Complexity M | Complexity L                                           |
|------------|-------------------------------------|--------------|--------------------------------------------------------|
| 🔴 Blocker | ✅ Fix here                          | ✅ Fix here   | ✅ Minimal fix here **+** 🕐 follow-up for the real fix |
| 🟠 Major   | ✅ Fix here                          | ✅ Fix here   | 🕐 Follow-up, explicitly agreed with the reviewer      |
| 🟡 Minor   | ✅ Fix here (leave it cleaner, 🏕)   | 🕐 Follow-up | 🕐 Follow-up                                           |
| 🔵 Nit     | ✅ Fix here if the diff budget holds | ❌ No action  | ❌ No action                                            |

Overrides, which win over the grid:

- **Out of the change's scope** → 🕐 or ❌, never ✅. Growing the diff past 200 lines / 10 files costs the review more than the fix is worth.
- **Pre-existing, not introduced here** → 🕐 by default, whatever its severity — except 🔴, which is fixed or blocks the merge regardless of who wrote it.
- **A 🔴 too big for this change** → block the merge and open a dedicated PR. Never a 🕐.
- **Wrong, speculative, or already handled elsewhere** → ❌.
- **A preference the user cannot justify to themselves** → ❌. But a reviewer's request that merely *arrives* without a stated reason is not a ❌: ask for the reason, then score the answer. Reviewers owe a justification; that duty is not a licence to dismiss them when they forget it.

When the emoji conventions are in use, read them as **intent only** — what the reviewer expects. A 🔧 can be factually wrong (→ ❌), a 💭 can uncover a real crash (→ 🔴 ✅), and a comment with no emoji is scored exactly the same way. The emoji never sets severity and never sets the outcome.

### Step 5 — Present the plan, then stop

Output these three parts, and **change nothing in this step**.

**1. Summary table** — one row per finding, none omitted, ordered by severity then complexity:

| # | Finding                                   | Severity | Impact                 | Complexity | Recommendation |
|---|-------------------------------------------|----------|------------------------|------------|----------------|
| 1 | `SpellRepository.kt:42` — unbounded cache | 🟠 Major | Functional + technical | M          | ✅ Fix here     |

**2. Detail block per finding**, carrying the rationale of the decision:

```markdown
### 1. `SpellRepository.kt:42` — unbounded cache growth

- **Severity**: 🟠 Major — the map never evicts, so a long session ends in an OOM
- **Impact**: functional + technical — users hit a crash; the cache is also untestable as written
- **Complexity**: M — hours for the eviction policy and its test, tens of lines across the two files the change already touches
- **Recommendation**: ✅ Fix here — cap the map at 100 entries with an LRU eviction
- **Rationale**: introduced by this change, user-visible failure mode, and the fix stays inside the current diff. Deferring it would ship a known crash.
```

The rationale explains the **trade-off** — why the other two outcomes were rejected — not the finding again.

**3. Action plan**, grouped by outcome:

- **✅ To fix here** — the ordered list of edits, with the files each one touches.
- **🕐 To defer** — on the user's own change: for each, the ticket ready to submit (title, body with context, `file:line`, why it is deferred, link to the PR) and the tracker it goes to. On someone else's change: the scored comment to leave, and the note that the ticket is the author's call.
- **❌ No action** — one line each with its reason.

End your turn with a question such as "Shall I apply this plan?". Wait for the user to approve, adjust, or override — the recommendations are proposals, and the person who owns the code decides.

### Step 6 — Execute after approval

Once approved, in this order:

1. **Apply the ✅ fixes.** Verify the project still builds and tests still pass where a command exists.
2. **Open the 🕐 tickets** — only for the user's own change, only in the tracker identified at Step 3, and only after showing the final title and body. This skill holds no forge permissions by design, so `gh issue create` — or whatever the project's tracker needs — is prompted every time. That prompt is the feature, not the friction. **Never open a ticket in another author's name.**
3. **Reference the follow-ups in the PR description** — append or update a `## Follow-ups` section:

   ```markdown
   ## Follow-ups

   - [#142](https://github.com/org/repo/issues/142) — 🟠 cache has no eviction policy (deferred: needs an ADR on cache sizing)
   - PROJ-318 — 🟡 extract the pagination logic shared with `SpellListScreen`
   ```

   Read the current body first, splice the section in, and write it back — never overwrite a description you have not read. Like the ticket creation, this call is prompted.

4. **Anchor deferred findings in the code** when they belong to a specific place: a `TODO(#142):` naming the ticket.

### Step 7 — Commit only on explicit approval

**Never run `git add`, `git commit`, or `git push` without explicit user approval** — they are absent from `allowed-tools` for that reason. Summarise what changed, then ask:

> "May I commit and push these changes? Branch: `<branch>`, suggested commit message: `<conventional-commit-message>`"

The commit message follows Conventional Commits and carries **no AI attribution** — no `Co-Authored-By` for AI assistants, no `🤖 Generated with` footer. If the project provides a `/commit` skill, use it to split the fixes into atomic commits.

## Rules

- Every finding gets a decision. "Worth considering" is not a decision.
- Nothing is silently dropped: a finding we skip appears in the table as ❌ with its reason.
- Severity is about consequences, not taste.
- A deferral is owned by whoever owns the code. Never file a ticket in someone else's name unasked.
- Never widen the diff beyond what the change is about — that is what 🕐 is for.
- The plan comes before any change, always.
