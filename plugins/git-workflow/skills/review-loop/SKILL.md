---
name: review-loop
description: >-
  Make an open pull request converge: answer the open review threads first, then run review → triage
  → fix → commit rounds, each on a fresh review, until a round leaves nothing to fix or the round cap
  is reached; then push once, post the replies, open the follow-ups, refresh the description and
  label the PR with its review status. Run manually after the first human read of a PR, instead of
  repeating review, triage and commit by hand.
argument-hint: "[--auto] [--max N] [low|medium|high]"
disable-model-invocation: true
# Local reads and local commits only. Invoking this skill is the approval for the loop's local
# commits. Everything that leaves the machine — the push, thread replies and resolutions, tickets,
# the PR description, labels — keeps its permission prompt on purpose.
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git branch:*)
  - Bash(git symbolic-ref:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(gh pr view:*)
  - Bash(gh repo view:*)
  - Bash(gh label list:*)
  - Read
  - Grep
  - Glob
  - Edit
  - Write
---

<!--
The loop — round 0, the round, the stop conditions, the closing order and the status labels — is
derived from collaboration/code-review-loop.md in cyrillrx/coding-conventions. Keep it in sync with
/sync-plugins. Scoring and replies are not restated here: they belong to triage-findings and
address-review, which this skill calls.
-->

## Context

- Arguments: $ARGUMENTS
- Current branch: !`git branch --show-current`
- Remote default branch: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo "unresolved — ask"`
- PR for this branch: !`gh pr view --json number,title,state --jq '"#\(.number) \(.state) — \(.title)"' 2>/dev/null || echo "none"`
- Uncommitted changes: !`git status --short`

## Your task

Run the loop below to its end. Between rounds, do not stop to ask whether to continue: the only stops are the ones this skill names.

### Step 1 — Check the preconditions and read the arguments

- **A PR is open for this branch.** If none, stop and point to `/git-workflow:pull-request`: the loop starts after the author's first read of an open PR, never before.
- **The working tree is clean.** Uncommitted changes would be swept into the loop's commits; if there are any, stop and ask.
- **The base branch is resolved**, as `triage-findings` Step 2 does it. If it is unresolved, ask.
- **The verification commands** — how this project builds and runs its tests, from `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` or the build files. If there are none, say so once: the rounds then commit without a build check.
- **Arguments**: `--auto` lets the grid decide (Step 3); `--max N` sets the round cap — 4 by default, and never above 10, whatever is asked; `low`, `medium` or `high` is the review effort, `high` by default.

### Step 2 — Round 0: the open review threads

Fetch the PR's unresolved review threads with the query in `address-review` Step 2. If there are none, go to Step 3.

Otherwise, follow `address-review` Step 3: one proposed response per thread, then **wait for the author's approval, even with `--auto`** — a person is waiting, and the reply goes out in the author's name. Then:

- apply the ✅ responses, run the verification commands, and commit with `/git-workflow:commit --auto`;
- **hold every reply and every resolution**: they are posted in Step 4, after the push, so no "Fixed" points at code the reviewer cannot see yet;
- record any ⚠️ Discuss thread: it stays open, and it decides the status label;
- add each 🕐 Defer thread's ticket to the follow-up list Step 4 opens: its held reply names that ticket once it exists.

Round 0 does not count toward the cap.

### Step 3 — The rounds

For round `i` from 1 to the cap:

1. **Review and triage**: run `/git-workflow:triage-findings --review <effort>`. `--review` makes it start from a fresh review in a subagent, never from the findings earlier rounds left in this conversation.
2. **Decide**:
   - by default, present the round's plan and **wait for one approval for the whole batch** — the author may adjust any line;
   - with `--auto`, the grid's recommendations stand, and the round stops for the author only on what the grid does not settle: a 🔴 with complexity L, a ❌ on a 🟠 or a 🔴, a finding that is ambiguous or that contests an earlier decision.
3. **Collect the 🕐** — keep each ready-to-submit ticket from the plan in a running list, and do not file it now: `triage-findings` Step 6.2 to 6.4 are deferred to Step 4.
4. **Converged?** If the approved plan holds no ✅, the loop has converged: go to Step 4.
5. **Apply** the ✅ fixes, as `triage-findings` Step 6.1 does. Run the verification commands; if they fail, fix the failure within the round, or stop the loop as blocked. When blocked, keep what passes: commit the fixes that are green on their own, stash the rest so no later commit picks it up, and name the stash in the report. **Never commit a red build** — but a green fix is not lost to a red neighbour.
6. **Commit** the round with `/git-workflow:commit --auto` — atomic Conventional Commits, no AI attribution. `--auto`, because invoking this skill was the approval. Do not push.

If round `cap` committed fixes, the loop stops at the cap: say so, and go to Step 4. Never run an extra round to round things off.

### Step 4 — Close the loop

In this order:

1. **Follow-ups** — show at once every collected 🕐 ticket the author has not approved yet, open the approved ones in the tracker `triage-findings` Step 3 identified, add the `TODO(#n):` anchors where they belong, and commit those anchors.
2. **Push** the branch, once. This call is prompted.
3. **Replies** — post the round 0 replies held in Step 2 and resolve the threads `address-review` Step 6 would resolve. Each call is prompted.
4. **Description** — run `/git-workflow:pull-request` to bring the description back in line with the diff, with the opened follow-ups under `## 🔁 Follow-ups`.
5. **Status label** — `review: clean` if the loop converged and no round 0 ⚠️ thread is open; `review: findings` otherwise. A 🕐 with its ticket does not count as pending; a 🕐 left without one does. Check that both labels exist with `gh label list`, and create any that is missing (`gh label create "review: clean" --color 0E8A16`, `gh label create "review: findings" --color D93F0B`). Then set one and remove the other in a single call: `gh pr edit <n> --add-label "<label>" --remove-label "<other>"`. These calls are prompted.
6. **Report**, for the author's final read:
   - rounds run, and why the loop stopped — converged, cap, or blocked on what;
   - the fixes, round by round, with their commits;
   - the follow-ups opened, and the findings dismissed with their reason;
   - for `review: findings`, what is still pending;
   - the SHA that was reviewed: the label describes that commit, and any later push makes it stale.

## Rules

- The author reads the PR before the loop and after it; the loop replaces neither read.
- A person's comment is answered by the author's decision, never by `--auto`.
- No reply claims a fix that is not pushed.
- No round commits a red build.
- Every finding of every round gets a decision — `triage-findings` owns how.
- Never more than 10 rounds.
