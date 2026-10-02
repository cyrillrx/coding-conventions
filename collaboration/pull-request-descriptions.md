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

| Direction                                  | Question                                     | Symptom                                                            |
|--------------------------------------------|----------------------------------------------|--------------------------------------------------------------------|
| Description → diff                         | Does every claim still hold?                 | A sentence describing code that was since rewritten or reverted    |
| Diff → description                         | Does every change have a claim?              | A commit landed and nothing in the prose mentions it               |

The second is the one that gets missed. Group the changed files, and account for each group: it is either described, or deliberately left unmentioned because it is noise (a formatting pass, a generated file). Silence by oversight and silence by choice look identical in the final text — only the check tells them apart.

## 3. Sections have a lifecycle

The template says to delete the sections that do not apply. The harder case is the section that **stopped** applying.

A section written to explain a problem — a failing quality gate, a known regression, a temporary workaround — must be removed once the problem is gone, not left as a historical note. It was addressed to reviewers of a state that no longer exists, and it will read as a live caveat in the commit message forever.

Re-examine, on every refresh:

- **🔁 Follow-ups** — every issue cited must exist and still be open. A deferral that was finally fixed in the PR leaves this list; a new one decided during review joins it. See [Code Review Triage](code-review-triage.md) for what earns a follow-up rather than a fix.
- **🤔 Considered and not addressed** — a suggestion that was eventually applied no longer belongs here.
- **🖼️ Media** — a screenshot of a screen the branch has since changed is worse than no screenshot.
- **✅ Checklist** — tick only what the diff proves, and annotate what cannot apply as `(N/A, <reason>)`. "CI is green" is a fact to verify, not a hope. "The author has proofread the PR" is the author's to tick, and nobody else's.

## 4. The description is a commit body

Because the squash makes it one.

- Lead with the *why*. The diff already shows the what; the description exists for what the diff cannot say.
- One line per paragraph and per bullet, per the [documentation conventions](../conventions/docs-conventions.md) — the forge soft-wraps, and a hard wrap turns a one-word edit into a reflowed block.
- English, like the commits it will become.
- A bullet per logical change, in the order a reader needs them, not in commit order. Commit order is an artifact of how the work happened; nobody reading the merged history cares.

## 5. The title follows the diff too

The title is a Conventional Commit, so its type and scope are claims about the change, and they expire like any other.

- A `refactor` that grew a visible behaviour change is a `feat` or a `fix`. The type describes what shipped, not what was intended at branch time.
- The scope narrows or widens with the files actually touched.
- Renaming a PR is cheap and silent. Leaving a wrong type is neither, since it propagates into the changelog.
