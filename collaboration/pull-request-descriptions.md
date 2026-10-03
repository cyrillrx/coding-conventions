# Pull Request Descriptions

[Git & Collaboration](git-and-collaboration.md) §7 says what a description must contain. This document says how to keep it true as the branch moves.

A description is written once and read last. Between the two, commits land, review findings get fixed, CI turns green, and every one of those events can make a sentence false. The cost is not cosmetic: when the PR is squashed, this text becomes the commit message, and a stale claim outlives the PR that carried it.

## 1. The diff of record

Every check below compares the description to one thing: the diff the reviewer will see.

- **Resolve the base branch, never assume `main`.** `git symbolic-ref --short refs/remotes/origin/HEAD` gives the remote's default; a project on GitFlow, or a PR stacked on a release branch, targets something else. Ask when the ref is missing.
- **Compare remote to remote**: `origin/<base>...origin/<head>`. A local `main` that has not been fetched silently widens the range to include other people's merged work, and `main...HEAD` fails at nothing while measuring the wrong change.
- **Three dots, not two.** `..` shows what the base gained as well; `...` shows what this branch added since they diverged, which is what is under review.

## 2. Reconciliation runs both ways

A description drifts in two directions, and only one of them is obvious.

| Direction            | Question                        | Symptom                                                          |
|----------------------|---------------------------------|------------------------------------------------------------------|
| Description → diff   | Does every claim still hold?    | A sentence describing code that was since rewritten or reverted  |
| Diff → description   | Does every change have a claim? | A commit landed and nothing in the prose mentions it             |

The second is the one that gets missed. Group the changed files, and account for each group: it is either described, or deliberately left unmentioned because it is noise (a formatting pass, a generated file). Silence by oversight and silence by choice look identical in the final text — only the check tells them apart.

A long-lived branch drifts a third way, and neither direction above catches it: **the base moved**. A merge into the base can change the template, the section list or the rules a description is written against, leaving a text that is accurate about its diff and wrong about the convention. Re-read §7 and the project's template on any refresh that follows a merge into the base, not just the description.

## 3. Sections have a lifecycle

The template says to delete the sections that do not apply. The harder case is the section that **stopped** applying.

A section written to explain a problem — a failing quality gate, a known regression, a temporary workaround — must be removed once the problem is gone, not left as a historical note. It was addressed to reviewers of a state that no longer exists.

Re-examine, on every refresh:

- **📝 Description** — still two short paragraphs at most. A refresh adds claims; it must not let the section grow into the reviewer guidance and the reasoning history that §7 sends elsewhere.
- **🔍 Review notes** — where to start, what is mechanical, what deserves attention. Guidance for a state the branch has left is worse than none: a "start with the parser" that no longer exists sends the reviewer looking for it.
- **🔁 Follow-ups** — every issue cited must exist and still be open. A deferral that was finally fixed in the PR leaves this list; a new one decided during review joins it. See [Code Review Triage](code-review-triage.md) for what earns a follow-up rather than a fix.
- **🤔 Considered and not addressed** — a suggestion that was eventually applied no longer belongs here.
- **🖼️ Media** — a screenshot of a screen the branch has since changed is worse than no screenshot.
- **✅ Checklist** — tick only what the diff proves, and annotate what cannot apply as `(N/A, <reason>)`. "CI is green" is a fact to verify, not a hope. "The author has proofread the PR" is the author's to tick, and nobody else's.
- **`Closes #N`** — the last lines, after the checklist. An issue the branch stopped closing must lose its line, or merging silently closes work that is still open.

## 4. The Description section is a commit body

Because the squash makes it one — that section alone, per §7. Everything below it serves the review and dies with the PR, which is what makes the Description the only part a refresh must weigh against the permanent history.

- The problem, then what the PR changes. Two short paragraphs at most, per §7. A refresh is where this budget is lost: each new commit invites one more sentence, and nothing pushes back.
- Lead with the *why*. The diff already shows the what.
- Order the changes as a reader needs them, never in commit order. Commit order is an artifact of how the work happened; nobody reading the merged history cares.
- English, like the commit it becomes. One line per paragraph and per bullet, per the [documentation conventions](../conventions/docs-conventions.md) — the forge soft-wraps, and a hard wrap turns a one-word edit into a reflowed block.
- What no longer fits has a destination, not a deletion: reviewer guidance to **Review notes**, the investigation to the linked issue, an architecture decision to an [ADR](git-and-collaboration.md#9-architecture-decision-records-adrs).

## 5. The title follows the diff too

The title is a Conventional Commit, so its type and scope are claims about the change, and they expire like any other.

- A `refactor` that grew a visible behaviour change is a `feat` or a `fix`. The type describes what shipped, not what was intended at branch time.
- The scope narrows or widens with the files actually touched.
- Renaming a PR is cheap and silent. Leaving a wrong type is neither, since it propagates into the changelog.
