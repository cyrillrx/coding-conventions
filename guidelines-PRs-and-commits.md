# Guidelines about PRs and commits

## Commit message structure

A commit message should help the reviewers to get some context around a PR, but more importantly should help for investigation while attempting to fix nasty regression bugs.
A well-written commit history is a very nice hint to quickly spot the origin of a bug by the information that it contains.
Also for features and UX/UI changes you should add screenshots and videos.

The general structure of a commit message should be as following:
```
[Type] ISSUE-ID - Short title

Description preceded by an intentionally skipped line and having the
lines hard-wrapped at 70 columns.

Other paragraphs might be added, and all the markdown formatting is
encouraged to be used, like lists:
* first item
* second item

or code quotes: `ItemClass`

https://your-tracker.example.com/browse/ISSUE-ID
```

### Commit structure breakdown

#### Type

Describes the type of the work done in the commit, or its scope.
This can be one of these values (despite the list is not exhaustive):

* *Feat*: New features or improvement
* *UI*: Changes in the UI
* *Tech*: Tech purpose improvement (style, refacto, perf, etc.)
* *Tracking*: Update tracking outputs or internal mechanics
* *Test*: Commit focused on writing tests
* *Build*: Changes on the build system or CI scripts
* *Docs*: Commit focused on adding documentation
* *Fix*: Bugs solving

#### Short title

Describes what the commit does. This should be short and concise enough so that it **fits on a single line and in the 70 chars limit** of that line. Longer titles will often be truncated in most version system hosting platforms (like GitHub or GitLab).
Also, the title should always **start with a verb in infinitive** form like so:
> Add new constants for tracking events

As we were reading "By applying this commit, it will add new constants for tracking events".

#### Description

The description should help giving some context around the changes in the code, that would help any one to understand in which way it was done, and what was the intention of the commit. To sum it up, the description should both help a reviewer when the commit is in the pull request stage, or any developer looking for the cause of a bug.

There are no mandatory things to mention in the description but bear in mind that any useful information written down there will potentially save precious time when investigating a nasty bug, or avoid redoing the same mistake if the cause of the bug was an attempt to fix another bug. Spending 5 minutes to write a nice helpful description will always be better than spending several hours or days on a well-hidden bug cause.

Talking about formatting, it should of course be kept in the 70-characters-by-line limit to avoid weird display in some tools.

#### Issue identifier

Finally, the commit message should be terminated by a line mentionning "Resolves:" or "Fix:" followed by the ID of the issue (for instance the Jira ticket number). If the commit is solving many issues at once, they should be simply separated by a comma:

> Resolves: JIRA-99, JIRA-103

Also, other ticket references can be mentionned in the description, along with links if relevant (especially for the crashlytics issues).

# Pull requests

All of the above applies when creating a Pull Request:
The Pull Request's title and description should follow the previously enounced rules.

Also, **when squashing** your commits before merging to master, **be careful not to leave the working commit list as your resulting commit description**.
Either copy the PR description into the resulting commit's description or rewrite it altogether.

## Rules for authors
* Keep the diff under 200 lines and 10 files when possible. For mechanical changes (renaming, moving files), exceptions are acceptable.
* Proofread your own PR before submitting it for review. Check diff, description, and comments.
* Assign reviewers directly on GitHub.

## Rules for reviewers
* Review PRs within 24 hours when possible.
* If you're short on time, don't rush. An unreviewed PR is better than a rubber-stamped one.
* Be constructive and kind: critique the code, not the author.
* Back your comments with sources (docs, articles, benchmarks) rather than personal preference. Avoid arguments from authority. Don't request changes you can't justify.
* Use [Code Review Emojis](code-review-emojis.md) to add meaning to your comments (blocking vs. non-blocking, suggestion vs. question, etc.).
