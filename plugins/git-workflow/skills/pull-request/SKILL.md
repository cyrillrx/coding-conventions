---
name: pull-request
description: >-
  Open a pull request, or bring an existing one's title and description back in line with its diff.
  Reconciles both ways — every claim in the prose against the diff, and every change in the diff
  against the prose — then rewrites only what drifted. Use when asked to create a PR, to update or
  refresh a PR description, or after pushing commits that the description does not yet mention.
argument-hint: "[pr-number | --refresh]"
allowed-tools:
  - Bash(git branch:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git status:*)
  - Bash(git fetch:*)
  - Bash(git symbolic-ref:*)
  - Bash(gh pr view:*)
  - Bash(gh pr diff:*)
  - Bash(gh pr list:*)
  - Bash(gh pr checks:*)
  - Bash(gh issue view:*)
  - Bash(gh issue list:*)
  - Bash(gh repo view:*)
  - Read
---

<!--
The reconciliation procedure, section lifecycle and title rules in this skill are derived from
collaboration/pull-request-descriptions.md, and the authoring rules from git-and-collaboration.md §7,
in cyrillrx/coding-conventions. Keep them in sync with /sync-plugins.

`gh pr create` and `gh pr edit` are deliberately absent from allowed-tools: they are what publishes
the text, and that prompt is the last checkpoint before the author's prose reaches the forge.
-->

## Context

- Argument: $ARGUMENTS
- Current branch: !`git branch --show-current`
- Remote default branch: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo "unresolved — ask"`
- PR for this branch: !`gh pr view --json number,title,state --jq '"#\(.number) \(.state) — \(.title)"' 2>/dev/null || echo "none"`

## Your task

Write the prose. Do not touch code, and do not commit — if the diff needs a change, say so and stop.

Follow these steps in order.

### Step 1 — Settle the mode

| Argument         | Mode        | Target                                 |
|------------------|-------------|----------------------------------------|
| a number         | refresh     | that PR                                |
| `--refresh`      | refresh     | the PR of the current branch           |
| empty, PR exists | refresh     | the PR of the current branch           |
| empty, no PR     | create      | a new PR from the current branch       |

An empty argument on a branch that already has a PR is a refresh, never a second PR. Say which mode you picked before going further, so a misread is caught in one line rather than at the end.

In **create** mode, stop and say so if the branch is `main` or the resolved default: there is nothing to open a PR from. Check for unpushed commits (`git log origin/<head>..HEAD`) and push before creating, or the PR opens on an incomplete diff.

### Step 2 — Establish the diff of record

Resolve `<base>` from the remote's default branch, shown in the Context above. **Never assume `main`.** When the ref is unresolved, or the project targets a `develop` or a release branch, ask — a wrong base does not fail, it silently measures the wrong range.

```bash
git fetch origin
git diff --stat origin/<base>...origin/<head>
git log --oneline origin/<base>..origin/<head>
```

Three dots for the diff: `..` would also show what the base gained since the branch left it. In refresh mode, `gh pr diff <number>` gives the same range as the forge computes it, and is the safer cross-check when the branch has been rebased.

Note the size against the 200 lines / 10 files budget. Over it, the description must earn the exception — a mechanical rename, a generated file — or the PR wants splitting, which is the first line of the checklist.

### Step 3 — Read what exists

In **refresh** mode, read the current description before writing anything:

```bash
gh pr view <number> --json title,body --jq '.body'
```

Never regenerate a description from the diff alone. The prose holds decisions the diff cannot show — why an approach was chosen, what a reviewer already asked and got answered. Rewriting from scratch throws those away and asks the reviewer to re-read a text they had already approved. Splice; do not replace.

In **create** mode, read the project's `.github/pull_request_template.md`. Use the project's copy, not a remembered one — projects adapt it. If there is none, fall back to the sections of the shared template: Description, Media, Follow-ups, Considered and not addressed, Checklist.

Also read, in both modes, `AGENTS.md` / `CLAUDE.md` and any convention doc they point at. A project may impose its own commit scopes, a label convention for agent-related changes, or a language rule.

### Step 4 — Reconcile both ways

This is the step that exists. Run it in both directions and record the result; do not skip the second because the first came back clean.

**Description → diff.** Take each claim in the prose and find it in the diff. A claim that no longer holds is rewritten, not deleted silently — if the behaviour changed, the new behaviour is what the sentence should now say.

**Diff → description.** Group the changed files and account for every group: described, or deliberately unmentioned as noise (a formatting pass, a regenerated lockfile). This is the direction that gets missed, because nothing in the text points at what is absent from it.

Then re-examine each section for a lifecycle change:

- **🔁 Follow-ups** — verify each referenced issue exists and is open (`gh issue view <n> --json state`). Drop the ones fixed in the end; add the deferrals decided since. A follow-up with no issue is not a follow-up.
- **🤔 Considered and not addressed** — a suggestion that was eventually applied leaves this section.
- **🖼️ Media** — a screenshot of a screen the branch has since changed is worse than none. Flag it for the author; you cannot retake it.
- **✅ Checklist** — tick only what the diff proves. Annotate the inapplicable as `(N/A, <reason>)`. Verify "CI is green" with `gh pr checks` rather than assuming it. **Never tick "The author has proofread the PR"** — that box is the author's.
- **Any section the project added** to explain a transient problem — a failing quality gate, a known regression, a workaround — must be removed once the problem is gone. It was addressed to reviewers of a state that no longer exists, and the squash would carry it into the permanent history as a live caveat.

### Step 5 — Check the title

The title is a Conventional Commit, so its type and scope are claims that expire like the others.

- A `refactor` that grew a visible behaviour change is now a `feat` or a `fix`.
- The scope follows the files actually touched.
- Leave the title alone when it still fits. Renaming for style churns notifications for nothing.

### Step 6 — Present, then stop

Output, in this order:

1. **Mode, target and range** — one line: `refresh #273 · origin/main...origin/feat/x · 17 files, +315/−42`.
2. **What drifted** — one row per finding, with its direction.

   | # | Section      | Direction          | What is wrong                                     |
   |---|--------------|--------------------|---------------------------------------------------|
   | 1 | Description  | diff → description | The extraction in `core/` is in no bullet         |
   | 2 | Quality gate | lifecycle          | The gate it explains now passes; section is stale |

3. **The proposed title and body in full**, as they would be written. Not a patch, not a summary — the text, so it can be read as the reviewer will read it and as the squash will record it.

If nothing drifted, say exactly that and stop. A refresh that finds nothing is a successful refresh, not a reason to rewrite prose for its own sake.

End the turn with a question — "Shall I apply this?" — and wait. The description is the author's voice; the recommendations are proposals.

### Step 7 — Apply after approval

`gh pr create` and `gh pr edit` are absent from `allowed-tools` on purpose, so each one prompts. That prompt is the feature.

In refresh mode, write back the body **you read in Step 3 with your edits spliced in** — never a body you did not read, and never one fetched before the user's last change. Re-read immediately before writing if any time has passed:

```bash
gh pr view <number> --json body --jq '.body' > /tmp/pr-body.md   # splice, then:
gh pr edit <number> --body-file /tmp/pr-body.md
```

In create mode, `gh pr create --title "<conventional-commit-title>" --body-file <file>`. Do not add reviewers — per the conventions, the author assigns them on the platform. Carry **no AI attribution**: no `Co-Authored-By` for an assistant, no generated-with footer.

Then report what changed, and leave the proofreading checkbox for the author.

## Related skills

- `/git-workflow:commit` — splitting the working tree into atomic Conventional Commits. Run it before this skill, not after: the description describes commits that already exist.
- `/git-workflow:triage-findings` — deciding which review findings are fixed here and which become follow-ups. It owns the severity, impact and complexity scales; this skill only records the outcome in the 🔁 section. **Do not score findings here.**
- `/git-workflow:address-review` — replying to and resolving a reviewer's open threads. When someone is waiting for an answer, that skill comes first; this one then records what the exchange changed.
