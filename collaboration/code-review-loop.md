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
2. **A triage** of every finding, per [Code Review Triage](code-review-triage.md). The author approves the round's plan as one batch. When the author chooses to, the grid's recommendations stand without approval, and the round stops only on what the grid does not settle: a 🔴 with complexity L, a ❌ on a 🟠 or a 🔴, a finding that is ambiguous or contested, a ✅ fix that is structural. A fix is structural when its complexity is L or its diff would break the pull request's budget: it is flagged at triage, with the option to defer it, because the rounds that follow will spend themselves on what it reshapes.
3. **The ✅ fixes are applied**, the build and the tests pass, and the round is committed — one commit per logical unit, per [Git & Collaboration](git-and-collaboration.md). A round never commits a red build: it fixes the build or stops.
4. **The 🕐 follow-ups are collected**, not filed. They are opened together when the loop closes, so the author approves them once.
5. **The author chooses to go on or to stop.** Once a round has committed its fixes, the author sees a one-line summary with the trend so far — fixes and their severities, round after round — and decides whether the next round runs or the loop closes, even when the grid decides the triage alone. Further rounds are not always worth their cost, and only the author can say so. When the trend turns — fixes rising two rounds in a row, or a round fixing code an earlier round fixed — the diagnosis of [§4](#when-the-loop-does-not-converge) comes with the summary, without waiting for the cap.

## 4. When to stop

| Stop      | Condition                                                        | What it means                                                                          |
|-----------|------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| Converged | A round's triage holds no ✅                                     | The change is done, as far as review goes                                              |
| Cap       | The round cap is reached — 10 by default                         | Reviews keep finding work: the loop diagnoses why, and the author closes or extends it |
| Stopped   | The author ends the loop after a round                           | The last fixes were never reviewed: the author judged another round not worth its cost |
| Blocked   | A decision needs the author, or the build cannot be made to pass | The loop cannot go further on its own                                                  |

Reaching the cap is a signal, not a failure to hide, and it is not a hard limit either: it is a decision point. An extension is never silent — the author chooses it, after the diagnosis below, as a block of a few more rounds that ends on the same decision point.

### When the loop does not converge

The form of the diagnosis is fixed; its content is not:

1. **The trajectory** — the fixes per round, with their severities.
2. **What is observed** — each observation with its evidence: the files, the findings, the rounds. When no cause stands out, the diagnosis says so rather than invent one.
3. **One recommendation**, then the choice: close the loop, extend it by a few rounds, or close it and act on the recommendation.

Common causes, as examples of the expected level — an observable signal and what it implies — not as a list to fit every case into. A cause outside it, or several mixed, is a valid diagnosis.

| Cause                               | Signal                                                                                | Ways out                                              |
|-------------------------------------|---------------------------------------------------------------------------------------|-------------------------------------------------------|
| Slow convergence                    | Fewer fixes each round, severities falling to 🟡 and 🟢                               | A few more rounds, or close: what remains is cosmetic |
| A cascade after a structural change | Findings concentrate on an area a fix reshaped                                        | See below                                             |
| A noisy review                      | Dismissed (❌) or contested findings come back, or nearly everything is 🟢            | Close, or run again at a lower review effort          |
| A change too broad                  | Findings spread over unrelated areas, the diff beyond the 200 lines / 10 files budget | Close, and split the pull request                     |

A cascade after a structural change is often expected, and its trend decides the way out:

- **Keep reviewing** when the findings on the area shrink from round to round: the cascade is settling.
- **Have a person read the area, then start a new loop** when they do not shrink, or change nature every round: the design is in question, not its execution.
- **Revert the structural change and defer it** — a 🕐 follow-up or a pull request of its own — when it reaches beyond the subject of this one.

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

| Label              | Set when |
|--------------------|---|
| `review: clean`    | The loop converged, and no round 0 thread is left open on a discussion |
| `review: findings` | The loop was closed at the cap or by the author's choice — its last fixes were never reviewed — or blocked, or a discussion thread is open |

A 🕐 that has its ticket does not count as pending: it is decided and traced. The label describes the commit that was reviewed; any later push makes it stale, and the next loop sets it again.

## 7. Non-negotiables

- The author reads the pull request before the loop and after it.
- A comment from a person is answered by the author's decision, never by a default.
- No reply claims a fix that is not pushed.
- No round commits a red build.
- Every finding of every round gets a decision, per [Code Review Triage](code-review-triage.md).
