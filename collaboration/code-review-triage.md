# Code Review Triage

A review that only lists problems moves the work to the reader. This document defines how a review finding becomes a **decision**: what it costs to ignore, what it costs to fix, and what we do about it: now, later, or never.

It applies to any finding, whatever its source: a human reviewer, an automated review tool, a linter, or a self-review before opening the PR.

The grid and the overrides in [§5](#5-recommendation) cover the common cases, not every case. A finding that falls outside them still gets a decision and a rationale: the five axes apply, and the judgement is yours. This is a shared default, not an exhaustive rulebook.

This document scores a finding; it never speaks to its author. How a comment is answered on a pull request (the reply, its tone, which threads get resolved) belongs to [Code Review Comments](code-review-comments.md#responding-to-a-comment).

## 1. Every finding is scored on five axes

| Axis               | Question it answers                          |
|--------------------|----------------------------------------------|
| **Severity**       | What happens if we ship it as is?            |
| **Impact**         | Who pays for it: users, developers, or both? |
| **Complexity**     | What does it cost to address?                |
| **Simplicity**     | Does the fix make the code simpler?          |
| **Recommendation** | What do we do, and why?                      |

A finding without these five axes is an observation, not a review outcome.

## 2. Severity

| Level          | Meaning                                                                                             | Blocks the merge? |
|----------------|-----------------------------------------------------------------------------------------------------|-------------------|
| 🔴 **Blocker** | Data loss, security hole, crash, or regression on the path the PR touches. Ships broken.            | Yes               |
| 🟠 **Major**   | Wrong behavior in an edge case, broken contract, significant perf cost, or untested critical logic. | Negotiable        |
| 🟡 **Minor**   | Maintainability or convention issue: unclear naming, duplication, missing doc. No behavior change.  | No                |
| 🔵 **Nit**     | Pure preference or cosmetics. Never blocking, never argued.                                         | No                |

Severity describes the **consequence of shipping**, not how annoying the code looks. A very ugly piece of code with no functional consequence is 🟡, not 🟠.

Not blocking is not the same as not addressed. A finding that stands is fixed here or deferred with a trace, never dropped, because letting maintainability and conventions erode is a decision nobody meant to take. The 🔵 is the only severity that can be dismissed while still standing: for it alone, "not worth its cost" is a sufficient reason. Dismissing anything heavier means contesting the finding itself, not its priority: say so, and score it again.

A false positive is not a severity followed by a ❌: invalidating a finding removes its severity. The notion only exists when you triage someone else's claim: when you score your own, you do not raise what you already know to be wrong.

## 3. Impact

State which dimensions the finding actually touches, and one line on who bears the cost. Only score the dimensions the PR can affect: a pure `refactor` PR normally has technical impact only, and claiming a functional impact there is a signal the refactor is not behavior-preserving.

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

They can disagree: a one-line fix sitting behind a day of investigation, a mechanical rename that adds 300 lines in ten minutes. When they do, **take the higher of the two as the rating**, and read each for what it actually decides: the diff says whether the finding fits in this PR at all, against the remaining 200 lines / 10 files budget; the effort says whether a deferral is a ticket someone picks up or a PR of its own.

## 5. Recommendation

Exactly three outcomes. Each one carries a rationale: the reason the other two were rejected.

| Outcome          | What it commits us to |
|------------------|---|
| ✅ **Fix here**  | Addressed in this PR. The recommendation must say **how**: the approach and the files involved, concretely enough to act. |
| 🕐 **Follow-up** | Deferred, with an owner and a trace (see [§6](#6-follow-ups)). Never a verbal "later". |
| ❌ **No action** | Nothing happens, on purpose. The rationale states why. |

❌ is deliberately weak. It spans everything from "this is wrong" to "correct, but not worth its cost", and most of the time it is simply a comment we skip, not a verdict on the code and not a refusal. Reserve heavier wording for the rare case that earns it; the default reading of a ❌ is "we looked, we decided, we moved on".

These are dispositions of a **finding**, not replies to a **person**: they decide what the codebase does, not what a reviewer is told. A 🔵 that is valid but not worth its cost is a ❌ here; it is never communicated as "your comment is wrong".

### Effect on simplicity

Once a finding is known to stand, one more question weighs on its outcome: **does the fix make the code simpler?** The grid judges a fix by its size, and size says what a fix costs the review, not what it leaves behind.

| Effect          | Signals | What it changes |
|-----------------|---|---|
| **Simplifies**  | Fewer concepts to hold, less duplication, one way to do each thing, functions with one job, a lighter read (no needless intermediate variable, no mental bookkeeping, names that remove the need for a comment). Often, not always, fewer lines | ✅ even for a 🔵, even past the diff budget: the fix pays down rather than adds |
| **Neutral**     | The code moves but reads the same | The grid applies as is |
| **Complicates** | One more concept, an indirection, a special case, a denser expression, more lines with no gain in clarity | It must be justified: a 🔵 becomes ❌; a 🟡 is a decision for the author, not for the grid (the finding stands, the remedy may cost more than the harm) |

**Fewer lines is evidence, not the test.** A change simplifies the code when a reader holds fewer concepts and does less work to understand it: less duplication, one way to do each thing, functions with one job, intermediate names only where they carry meaning. A shorter version that hides a concept in a dense expression, or merges two responsibilities, does not simplify; an intermediate variable that names a step can.

The effect weighs the remedy, never the scope: a simplifying fix outside the subject of the PR is still a 🕐, per the overrides below. For example:

- Two functions sharing the same shape, folded into one helper: simplifies, fewer lines. ✅
- A builder parameter added only to remove a few string replacements in tests: neutral to complicating. ❌
- A test split so each one holds one assertion, for the same cases: complicates, more lines. ❌
- A constant named in a test whose name already says what the value means: complicates. ❌

### Default decision grid

| Severity   | Complexity S                         | Complexity M  | Complexity L                                            |
|------------|--------------------------------------|---------------|---------------------------------------------------------|
| 🔴 Blocker | ✅ Fix here                          | ✅ Fix here   | ✅ Minimal fix here **+** dedicated PR for the real fix |
| 🟠 Major   | ✅ Fix here                          | ✅ Fix here   | 🕐 Follow-up, explicitly agreed with the reviewer       |
| 🟡 Minor   | ✅ Fix here (leave it cleaner, 🏕)    | 🕐 Follow-up  | 🕐 Follow-up                                            |
| 🔵 Nit     | ✅ Fix here if the diff budget holds | ❌ No action  | ❌ No action                                            |

The grid is the default, not the verdict. The effect on simplicity adjusts it, as above, and it is overridden by:

- **Out of the PR's scope** → 🕐 when it stands, ❌ when it is not worth a trace. The one exception is a 🏕 cleanup (a couple of lines with no behavior change, in a file the PR already touches), which may be ✅, in its own commit. Growing the diff past 200 lines / 10 files costs the review more than the fix is worth (see [PR etiquette](git-and-collaboration.md#7-pull-request-etiquette)).
- **Pre-existing, not introduced here** → 🕐 by default, whatever its severity.
- **The finding is wrong (the code already handles it, or does not do what it claims) or speculative** → ❌.
- **Already tracked by an open ticket** → 🕐 pointing at that ticket. No second ticket is opened: the existing one is the trace. A ❌ would read as "nothing will happen" when the work is planned.
- **On a decision document, a finding that changes none of [its six answers](decision-document-review.md#3-a-finding-changes-an-answer)** → ❌, whatever its source. When it is about a behavior, it is a finding on the code that implements it: anchor it there and score it again.
- **A preference you cannot justify to yourself** → ❌. But a reviewer's request that merely *arrives* without a stated reason is not a ❌: ask for the reason, then score it. Reviewers owe a justification ([PR etiquette](git-and-collaboration.md#7-pull-request-etiquette)); that duty is not a licence to dismiss them when they forget it.

Whatever the grid or an override gives, the recommendation is judged on the finding alone:

- **The state of a review loop is not a reason.** A recommendation never depends on whether it lets a [review loop](code-review-loop.md) converge or close. Convergence is an outcome of the triage, not a criterion of it.
- **A test that records a behavior does not justify it.** A ❌ that rests on "it is deliberate" traces the decision to a spec, an ADR or a commit message. Without such a trace, score the finding as if the behavior were unspecified: the test may only have recorded a side effect nobody decided.
- **Recommend the option you rate best.** When the rationale presents an alternative and calls it better, the recommendation is that alternative. Its cost goes into the complexity score, and from there into ✅ or 🕐. A ❌ whose own rationale calls the fix better is a contradiction, not a decision.

## 6. Follow-ups

A deferral needs **an owner and a trace**. Who provides them depends on whose change it is, and that is not a detail: opening a ticket in someone else's name is deciding their roadmap for them.

### On your own change: you are the owner

Self-review, or your own PR after a review. The deferral is yours to carry, so all three exist:

1. **A ticket** in whatever tracker the project actually uses. Its description carries the context: what was found, where (`file:line`), why it was deferred, and a link back to the PR. On a GitHub tracker, its severity, impact and complexity also go on it as labels, per [Issue Labels](issue-labels.md).
2. **A reference in the PR description**, under the `## 🔁 Follow-ups` section of the [PR template](../.github/pull_request_template.md), so the deferral is visible at merge time and in the merged history:

   ```markdown
   ## 🔁 Follow-ups

   - [#142](https://github.com/org/repo/issues/142): 🟠 cache has no eviction policy (deferred: needs an ADR on cache sizing)
   - PROJ-318: 🟡 extract the pagination logic shared with `SpellListScreen`
   ```

3. **A code reference** when the finding is anchored to a specific place: a `TODO(#142):` naming the ticket, per the [🕐 convention](code-review-comments.md#emoji-legend).

Here, a 🕐 with no ticket is a deferral in name only. If the ticket is not going to be opened, fix the finding here or say plainly that nothing will happen; an unnamed decision is the one that erodes the codebase.

### On someone else's change: the author is the owner

You are reviewing, so the decision to defer is not yours to make and the tracker is not yours to fill. **Hand the finding over rather than filing it:**

- Raise it as a 🕐 comment on the thread, scored (severity, impact, complexity) so the author can decide rather than guess. The thread itself is the trace.
- **Offer** the ticket; never open one in the author's name without asking. If they want it, they own it, or they ask you to open it, and then you do.
- If the author declines, that is their call and it is recorded in the thread. Do not re-litigate it, and do not open a ticket to work around the answer.
- The exception is a 🔴 the change introduces: it does not become a follow-up at all. It is fixed, or it blocks the merge.

Deferring your own finding on your own code and deferring someone else's finding on their code are different acts. Only the first one is a promise you can keep.

## 7. Coming from a review comment

The [Code Review Comments](code-review-comments.md) guide is how a finding is *communicated*; this document is how it is *decided*. The emoji tells you what the reviewer **expects**, nothing more:

| Emoji | What the reviewer expects                                     |
|-------|---------------------------------------------------------------|
| 🔧    | A change; they believe the behavior is wrong                  |
| ⛏     | A small improvement, explicitly not worth arguing over        |
| 🕐    | To defer this rather than grow the PR                         |
| 🏕     | An opportunistic cleanup next to the change, not caused by it |
| 💭 ❓ | An answer, or a discussion (not a change, yet)                |
| 📝 👍 | Nothing; it is a note or a compliment                         |

**The emoji never sets the severity and never sets the outcome.** Score on substance: a 🔧 can be factually wrong (→ ❌), a 💭 can uncover a real crash (→ 🔴 ✅), and a comment with no emoji at all (external reviewers, bots) is scored exactly the same way.

What the comment asks for maps to a disposition like this:

| The comment…                                           | Disposition                                                   |
|--------------------------------------------------------|---------------------------------------------------------------|
| asks for a change, and it stands                       | Score it: ✅ Fix here, or 🕐 when complexity and scope say so |
| needs no code change (note, praise, answered question) | Not a finding. Nothing to score                               |
| is unclear, or arrives with no stated reason           | Not a finding yet. Ask, then score the answer                 |
| does not stand                                         | ❌ No action, with the reason stated to the reviewer          |

## 8. Expected output

A triage produces three things, in this order.

**A summary table** (one row per finding, none omitted):

| #   | Finding                                  | Severity | Impact                 | Complexity | Simplicity | Recommendation |
|-----|------------------------------------------|----------|------------------------|------------|------------|----------------|
| F1  | `SpellRepository.kt:42`: unbounded cache | 🟠 Major | Functional + technical | M          | Neutral    | ✅ Fix here    |

**A detail block per finding**, carrying the rationale:

```markdown
### F1. `SpellRepository.kt:42`: unbounded cache growth

- **Severity**: 🟠 Major. The map never evicts, so a long session ends in an OOM
- **Impact**: functional + technical. Users hit a crash; the cache is also untestable as written
- **Complexity**: M. Hours for the eviction policy and its test, tens of lines across the two files the PR already touches
- **Simplicity**: neutral. The map gains a bound; its callers hold no new concept
- **Recommendation**: ✅ Fix here. Cap the map at 100 entries with an LRU eviction
- **Rationale**: introduced by this PR, user-visible failure mode, and the fix stays inside the current diff. Deferring it would ship a known crash.
```

**An action plan**, grouped by outcome: the fixes to apply, in the order they will be applied, the follow-up tickets to open (title and body ready to submit) or already open (their number), and the `## 🔁 Follow-ups` block to append to the PR description.

The summary table numbers the findings F1..Fn, and that number is a finding's only identifier. The detail blocks and the action plan refer to a finding by it, and nothing in the output starts a second numbered list: each line of the plan is a bullet led by the findings it addresses (`- F1, F4: cap the cache at 100 entries, in SpellRepository.kt`). The `F` keeps a finding apart from an issue number such as `#142`. An answer such as "F1 ok, F2 no" then has only one list it can mean.

## 9. Non-negotiables

- Every finding gets a decision. "Worth considering" is not a decision.
- Every recommendation carries a rationale, and the rationale explains the *trade-off*, not the finding.
- Severity is about consequences, not taste.
- Fewer lines is evidence of a simpler fix, not its test.
- A recommendation rests on the finding's merits, never on what it does to a review loop.
- Nothing is silently dropped: a finding we skip appears in the table as ❌ with its reason.
- A deferral is owned by whoever owns the code. Never file a ticket in someone else's name unasked.
- The plan is presented before anything is changed. Applying fixes, opening tickets, and editing the PR description all happen after the author has approved the plan.
