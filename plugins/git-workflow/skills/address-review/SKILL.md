---
name: address-review
description: Address open review comments on a PR, reply to each thread, resolve approved ones, then optionally re-run review. Use when asked to handle, address, or respond to PR review comments.
argument-hint: <pr-number>
allowed-tools:
  - Bash(gh api:*)
  - Bash(gh pr:*)
  - Bash(gh repo:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git branch:*)
  - Read
  - Edit
  - Write
---

<!--
Triage criteria in this skill reference collaboration/git-and-collaboration.md
in cyrillrx/coding-conventions. Keep them in sync with /sync-plugins.
-->

## Context

- PR number: $ARGUMENTS
- Current branch: !`git branch --show-current`

## Your task

Follow these steps in order.

### Step 1 — Identify the PR

If `$ARGUMENTS` is empty, run `gh pr list` and ask the user which PR to fix. Otherwise use `$ARGUMENTS` as the PR number.

### Step 2 — Fetch open review threads

Determine `<OWNER>` and `<REPO>` dynamically:

```bash
gh repo view --json owner,name -q '"\(.owner.login) \(.name)"'
```

Then get all unresolved review threads with their comments via the GraphQL API:

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $pr:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          comments(first:10) {
            nodes { databaseId body path line originalLine }
          }
        }
      }
    }
  }
}' -f owner=<OWNER> -f repo=<REPO> -F pr=<PR_NUMBER>
```

Filter for `isResolved: false` threads. If there are none, inform the user and stop.

> The query caps at 100 threads and 10 comments per thread. This covers normal PRs;
> the first comment (needed for `in_reply_to`) is always present. If a thread count
> of exactly 100 is returned, warn the user that older threads may be truncated
> rather than silently treating the batch as complete.

### Step 3 — Triage comments

For each unresolved thread, read the file at `path` around the relevant `line`, then present a triage table:

| # | File | Comment summary | Recommendation |
|---|------|-----------------|----------------|
| 1 | `path:line` | one-line summary | ✅ Apply / ⚠️ Discuss / ❌ Skip |

**Recommendation criteria:**
- ✅ **Apply** — valid, clear, consistent with the project's conventions, and backed by a justification or source.
- ⚠️ **Discuss** — requires a design decision, is ambiguous, or contradicts existing conventions.
- ❌ **Skip** — factually wrong, out of scope, already addressed, or not backed by any source or justification.

Per the team's conventions, reviewers are expected to back their requests with sources (docs, articles, benchmarks). A comment that expresses personal preference without justification should be marked ❌ or ⚠️. When in doubt, consult the project's conventions (`CLAUDE.md` / `AGENTS.md` and any linked convention docs).

Wait for the user to confirm, adjust, or override each recommendation before proceeding.

### Step 4 — Apply fixes and reply to all threads

For each thread, apply the outcome and post a reply via the REST API.

For **inline** review comments (attached to a file and line), use `in_reply_to` with the `databaseId` of the **first** comment in the thread:

```bash
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  -X POST -f body="<reply>" -F in_reply_to=<COMMENT_DATABASE_ID>
```

> Do **not** use `POST /pulls/comments/{id}/replies` — it returns 404 for comments
> created by bots (Gemini, CodeRabbit, etc.) and is unreliable in general.

The `reviewThreads` query in Step 2 only surfaces inline review threads, so the
reply above covers every thread you triaged. Only if the user explicitly asks you
to respond to a **general** PR comment (one with no associated file/line, which
never appears in `reviewThreads`) use the issue-comments endpoint instead:

```bash
gh api repos/<OWNER>/<REPO>/issues/<PR_NUMBER>/comments -X POST -f body="<reply>"
```

**Reply tone per outcome:**
- ✅ **Apply**: briefly confirm what changed (e.g. "Fixed — renamed `X` to `Y`.").
- ⚠️ **Discuss**: ask for clarification or a source.
- ❌ **Skip**: explain concisely why the comment is declined, citing conventions or sources where applicable.

Do not touch code for ⚠️ or ❌ threads.

### Step 5 — Ask for git permission

**Do NOT run any git commit, push, or rebase commands without explicit user approval.** `git add`, `git commit`, and `git push` are intentionally absent from `allowed-tools` so each git operation requires explicit confirmation.

Summarise the fixes made (files changed, what was fixed), then ask:
> "May I commit and push these changes? Branch: `<branch>`, suggested commit message: `<conventional-commit-message>`"

The commit message must follow Conventional Commits and carry **no AI attribution**. Wait for approval before proceeding.

### Step 6 — Commit, push, and resolve threads

Once the user approves:

1. Stage and commit the changes using the approved message.
2. Push to the current branch.
3. For each ✅ thread only, resolve it via GraphQL:

```bash
gh api graphql -f query='
mutation($threadId:ID!) {
  resolveReviewThread(input:{threadId:$threadId}) { thread { isResolved } }
}' -f threadId=<THREAD_ID>
```

⚠️ and ❌ threads are left open for the reviewer to follow up.

### Step 7 — Re-run review (if available)

If the project provides a `/review` skill or command, suggest running `/clear` first (to start a fresh context — review reads the full diff and all touched files), then invoke `/review <PR_NUMBER>`. Do **not** run `/clear` yourself. If no review skill exists, skip this step.
