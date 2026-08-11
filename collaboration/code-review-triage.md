# Code Review Triage

A review that only lists problems moves the work to the reader. This document defines how a review finding becomes a **decision**: what it costs to ignore, what it costs to fix, and what we do about it — now, later, or never.

It applies to any finding, whatever its source: a human reviewer, an automated review tool, a linter, or a self-review before opening the PR.

This document scores a finding; it never speaks to its author. How a comment is answered on a pull request — the reply, its tone, which threads get resolved — belongs to [Code Review Emojis](code-review-emojis.md).

## 1. Every finding is scored on four axes

| Axis               | Question it answers                           |
|--------------------|-----------------------------------------------|
| **Severity**       | What happens if we ship it as is?             |
| **Impact**         | Who pays for it — users, developers, or both? |
| **Complexity**     | What does it cost to address?                 |
| **Recommendation** | What do we do, and why?                       |

A finding without these four axes is an observation, not a review outcome.

## 2. Severity

| Level          | Meaning                                                                                             | Blocks the merge? |
|----------------|-----------------------------------------------------------------------------------------------------|-------------------|
| 🔴 **Blocker** | Data loss, security hole, crash, or regression on the path the PR touches. Ships broken.            | Yes               |
| 🟠 **Major**   | Wrong behavior in an edge case, broken contract, significant perf cost, or untested critical logic. | Negotiable        |
| 🟡 **Minor**   | Maintainability or convention issue: unclear naming, duplication, missing doc. No behavior change.  | No                |
| 🔵 **Nit**     | Pure preference or cosmetics. Never blocking, never argued.                                         | No                |

Severity describes the **consequence of shipping**, not how annoying the code looks. A very ugly piece of code with no functional consequence is 🟡, not 🟠.

Not blocking is not the same as not addressed. A 🟡 is fixed here or deferred with a trace — never dropped, because letting maintainability and conventions erode is a decision nobody meant to take. Only a 🔵 can end in ❌.

## 3. Impact

State which dimensions the finding actually touches, and one line on who bears the cost. Only score the dimensions the PR can affect — a pure `refactor` PR normally has technical impact only, and claiming a functional impact there is a signal the refactor is not behavior-preserving.

| Dimension      | Borne by   | Typical symptoms                                                              |
|----------------|------------|-------------------------------------------------------------------------------|
| **Functional** | Users      | Wrong result, crash, data corruption, security, perceived slowness, broken UX |
| **Technical**  | Developers | Maintainability, readability, testability, coupling, debt, build and CI time  |
| **Both**       | Everyone   | A design flaw that is already visible in behavior today                       |

## 4. Complexity to address

Two estimates, and one rating that carries them:

| Size  | Estimated effort | Estimated diff                                                 |
|-------|------------------|----------------------------------------------------------------|
| **S** | Minutes          | A few lines, inside files the PR already touches               |
| **M** | Hours            | Tens of lines, or one or two files added                       |
| **L** | A day or more    | Beyond what this PR can absorb: many files, a new area, an ADR |

Both estimates cover the test and the verification, not just the edit.

They can disagree — a one-line fix sitting behind a day of investigation, a mechanical rename that adds 300 lines in ten minutes. When they do, **take the higher of the two as the rating**, and read each for what it actually decides: the diff says whether the finding fits in this PR at all, against the remaining 200 lines / 10 files budget; the effort says whether a deferral is a ticket someone picks up or a PR of its own.

## 5. Recommendation

Exactly three outcomes. Each one carries a rationale — the reason the other two were rejected.

| Outcome          | What it commits us to                                                                                                     |
|------------------|---------------------------------------------------------------------------------------------------------------------------|
| ✅ **Fix here**   | Addressed in this PR. The recommendation must say **how**: the approach and the files involved, concretely enough to act. |
| 🕐 **Follow-up** | Deferred, with an owner and a trace — see [§6](#6-follow-ups). Never a verbal "later".                                    |
| ❌ **No action**  | Nothing happens, on purpose. The rationale states why.                                                                    |

❌ is deliberately weak. It spans everything from "this is wrong" to "correct, but not worth its cost", and most of the time it is simply a comment we skip — not a verdict on the code and not a refusal. Reserve heavier wording for the rare case that earns it; the default reading of a ❌ is "we looked, we decided, we moved on".

These are dispositions of a **finding**, not replies to a **person**: they decide what the codebase does, not what a reviewer is told. A finding that is valid but not worth its cost is a ❌ here — it is never communicated as "your comment is wrong".

### Default decision grid

| Severity   | Complexity S                        | Complexity M | Complexity L                                           |
|------------|-------------------------------------|--------------|--------------------------------------------------------|
| 🔴 Blocker | ✅ Fix here                          | ✅ Fix here   | ✅ Minimal fix here **+** 🕐 follow-up for the real fix |
| 🟠 Major   | ✅ Fix here                          | ✅ Fix here   | 🕐 Follow-up, explicitly agreed with the reviewer      |
| 🟡 Minor   | ✅ Fix here (leave it cleaner, 🏕)   | 🕐 Follow-up | 🕐 Follow-up                                           |
| 🔵 Nit     | ✅ Fix here if the diff budget holds | ❌ No action  | ❌ No action                                            |

The grid is the default, not the verdict. It is overridden by:

- **Out of the PR's scope** → 🕐 or ❌, never ✅. Growing the diff past 200 lines / 10 files costs the review more than the fix is worth (see [PR etiquette](git-and-collaboration.md#7-pull-request-etiquette)).
- **Pre-existing, not introduced here** → 🕐 by default, whatever its severity — except 🔴, which is fixed or blocks the merge regardless of who wrote it.
- **A 🔴 too big for this PR** → the merge is blocked and a dedicated PR is opened. It is never a 🕐.
- **The finding is wrong, speculative, or already handled elsewhere** → ❌.
- **A preference you cannot justify to yourself** → ❌. But a reviewer's request that merely *arrives* without a stated reason is not a ❌: ask for the reason, then score it. Reviewers owe a justification ([PR etiquette](git-and-collaboration.md#7-pull-request-etiquette)); that duty is not a licence to dismiss them when they forget it.

## 6. Follow-ups

A deferral needs **an owner and a trace**. Who provides them depends on whose change it is — and that is not a detail: opening a ticket in someone else's name is deciding their roadmap for them.

### On your own change — you are the owner

Self-review, or your own PR after a review. The deferral is yours to carry, so all three exist:

1. **A ticket** in whatever tracker the project actually uses. Its description carries the context: what was found, where (`file:line`), why it was deferred, and a link back to the PR.
2. **A reference in the PR description**, under a `## Follow-ups` section, so the deferral is visible at merge time and in the merged history:

   ```markdown
   ## Follow-ups

   - [#142](https://github.com/org/repo/issues/142) — 🟠 cache has no eviction policy (deferred: needs an ADR on cache sizing)
   - PROJ-318 — 🟡 extract the pagination logic shared with `SpellListScreen`
   ```

3. **A code reference** when the finding is anchored to a specific place — a `TODO(#142):` naming the ticket, per the [🕐 convention](code-review-emojis.md).

Here, a 🕐 with no ticket is a ❌ that nobody dares to name. If the ticket is not going to be opened, record the honest outcome instead.

### On someone else's change — the author is the owner

You are reviewing, so the decision to defer is not yours to make and the tracker is not yours to fill. **Hand the finding over rather than filing it:**

- Raise it as a 🕐 comment on the thread, scored — severity, impact, complexity — so the author can decide rather than guess. The thread itself is the trace.
- **Offer** the ticket; never open one in the author's name without asking. If they want it, they own it — or they ask you to open it, and then you do.
- If the author declines, that is their call and it is recorded in the thread. Do not re-litigate it, and do not open a ticket to work around the answer.
- The exception is a 🔴: it does not become a follow-up at all, whoever wrote the code. It is fixed or it blocks the merge.

Deferring your own finding on your own code and deferring someone else's finding on their code are different acts. Only the first one is a promise you can keep.

## 7. Coming from a review comment

The [Code Review Emoji Guide](code-review-emojis.md) is how a finding is *communicated*; this document is how it is *decided*. The emoji tells you what the reviewer **expects** — nothing more:

| Emoji | What the reviewer expects                                     |
|-------|---------------------------------------------------------------|
| 🔧    | A change; they believe the behavior is wrong                  |
| ⛏     | A small improvement, explicitly not worth arguing over        |
| 🕐    | To defer this rather than grow the PR                         |
| 🏕    | An opportunistic cleanup next to the change, not caused by it |
| 💭 ❓  | An answer, or a discussion — not a change, yet                |
| 📝 👍 | Nothing; it is a note or a compliment                         |

**The emoji never sets the severity and never sets the outcome.** Score on substance: a 🔧 can be factually wrong (→ ❌), a 💭 can uncover a real crash (→ 🔴 ✅), and a comment with no emoji at all — external reviewers, bots — is scored exactly the same way.

What the comment asks for maps to a disposition like this:

| The comment…                                           | Disposition                                                  |
|--------------------------------------------------------|--------------------------------------------------------------|
| asks for a change, and it stands                       | Score it: ✅ Fix here, or 🕐 when complexity and scope say so |
| needs no code change — note, praise, answered question | Not a finding. Nothing to score                              |
| is unclear, or arrives with no stated reason           | Not a finding yet. Ask, then score the answer                |
| does not stand                                         | ❌ No action, with the reason stated to the reviewer          |

## 8. Expected output

A triage produces three things, in this order.

**A summary table** — one row per finding, none omitted:

| # | Finding                                   | Severity | Impact                 | Complexity | Recommendation |
|---|-------------------------------------------|----------|------------------------|------------|----------------|
| 1 | `SpellRepository.kt:42` — unbounded cache | 🟠 Major | Functional + technical | M          | ✅ Fix here     |

**A detail block per finding**, carrying the rationale:

```markdown
### 1. `SpellRepository.kt:42` — unbounded cache growth

- **Severity**: 🟠 Major — the map never evicts, so a long session ends in an OOM
- **Impact**: functional + technical — users hit a crash; the cache is also untestable as written
- **Complexity**: M — an LRU policy plus its test, in the two files the PR already touches
- **Recommendation**: ✅ Fix here — cap the map at 100 entries with an LRU eviction
- **Rationale**: introduced by this PR, user-visible failure mode, and the fix stays inside the
  current diff. Deferring it would ship a known crash.
```

**An action plan**, grouped by outcome: the ordered list of fixes to apply, the follow-up tickets to open (title and body ready to submit), and the `## Follow-ups` block to append to the PR description.

## 9. Non-negotiables

- Every finding gets a decision. "Worth considering" is not a decision.
- Every recommendation carries a rationale, and the rationale explains the *trade-off*, not the finding.
- Severity is about consequences, not taste.
- Nothing is silently dropped: a finding we skip appears in the table as ❌ with its reason.
- A deferral is owned by whoever owns the code. Never file a ticket in someone else's name unasked.
- The plan is presented before anything is changed. Applying fixes, opening tickets, and editing the PR description all happen after the author has approved the plan.
