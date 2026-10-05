# Code Review Loop

A pull request rarely converges in one review. Fixing a round of findings changes the code, and the next review finds what the fixes introduced or uncovered. This document defines how to iterate — review, triage, fix — until a review leaves nothing to fix, while keeping a human where a human decides.

It builds on two documents and redefines neither: findings are scored and decided per [Code Review Triage](code-review-triage.md), and comments from people are answered per [Code Review Comments](code-review-comments.md#responding-to-a-comment).

## 1. When to loop

The loop starts on an open pull request that its author has already read once. It does not replace that first read, nor the last one: the loop makes the change converge, the author decides whether it is what they meant to ship.

## 2. Open comments come first

Before the first review round, the unresolved review threads left by people are handled — round 0. Someone is waiting on them, so:

- **The author decides every response**, always. A reply is published in their name, and a person's question is never answered by a default.
- **Fixes are committed with the loop**, and checked by the rounds that follow like any other change.
- **Replies are posted only once the fix is pushed.** A "Fixed" pointing at code the reviewer cannot see yet is a claim, not an answer.

Round 0 does not count toward the round cap.

## 3. One round

1. **A fresh review** of the whole change against its base branch. Fresh means a reviewer without the previous rounds in mind: a reviewer that remembers its own earlier fixes tends to confirm them rather than read them. Findings from earlier rounds are never carried over.
2. **A triage** of every finding, per [Code Review Triage](code-review-triage.md). The author approves the round's plan as one batch. When the author chooses to, the grid's recommendations stand without approval, and the round stops only on what the grid does not settle: a 🔴 with complexity L, a ❌ on a 🟠 or a 🔴, a finding that is ambiguous or contested.
3. **The ✅ fixes are applied**, the build and the tests pass, and the round is committed — one commit per logical unit, per [Git & Collaboration](git-and-collaboration.md). A round never commits a red build: it fixes the build or stops.
4. **The 🕐 follow-ups are collected**, not filed. They are opened together when the loop closes, so the author approves them once.

## 4. When to stop

| Stop      | Condition                                                        | What it means                                                                   |
|-----------|------------------------------------------------------------------|---------------------------------------------------------------------------------|
| Converged | A round's triage holds no ✅                                     | The change is done, as far as review goes                                       |
| Cap       | The round cap is reached — 4 by default, never more than 10      | Reviews keep finding work: the change may be too broad, or the review too noisy |
| Blocked   | A decision needs the author, or the build cannot be made to pass | The loop cannot go further on its own                                           |

Reaching the cap is a signal, not a failure to hide: the loop stops and reports what remains. There is no silent extra round.

## 5. Closing the loop

In this order:

1. **Follow-ups** — the collected 🕐 tickets are shown together, opened once approved, and anchored in the code where they belong (`TODO(#142):`), with that anchor committed.
2. **Push** — once, for the whole loop.
3. **Replies** — the round 0 replies are posted and the addressed threads resolved, per [Code Review Comments](code-review-comments.md#responding-to-a-comment).
4. **Description** — the pull request description is brought back in line with the diff, per [Pull Request Descriptions](pull-request-descriptions.md), and the follow-ups are listed under its `## 🔁 Follow-ups` section.
5. **Status label** — see [§6](#6-review-status-label).
6. **Report** — rounds run, fixes per round, follow-ups opened, findings dismissed and why, the reason the loop stopped, and the commit that was reviewed. It is what the author reads before the final human review.

## 6. Review status label

The loop leaves its outcome on the pull request as one of two labels, mutually exclusive — setting one removes the other:

| Label              | Set when                                                                                                      |
|--------------------|---------------------------------------------------------------------------------------------------------------|
| `review: clean`    | The loop converged, and no round 0 thread is left open on a discussion                                        |
| `review: findings` | The loop stopped at the cap — its last fixes were never reviewed — or blocked, or a discussion thread is open |

A 🕐 that has its ticket does not count as pending: it is decided and traced. The label describes the commit that was reviewed; any later push makes it stale, and the next loop sets it again.

## 7. Non-negotiables

- The author reads the pull request before the loop and after it.
- A comment from a person is answered by the author's decision, never by a default.
- No reply claims a fix that is not pushed.
- No round commits a red build.
- Every finding of every round gets a decision, per [Code Review Triage](code-review-triage.md).
