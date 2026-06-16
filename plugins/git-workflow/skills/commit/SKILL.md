---
name: commit
description: Stage and commit changes as multiple atomic Conventional Commits, one per logical unit. Use when the user asks to commit, or to split working changes into clean commits.
allowed-tools:
  - Bash(git add:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git commit:*)
  - Bash(git log:*)
  - Bash(git restore --staged:*)
  - Bash(git reset HEAD:*)
---

<!--
Conventions in this skill are derived from collaboration/git-and-collaboration.md
in cyrillrx/coding-conventions. Keep them in sync with /sync-plugins.
-->

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits (for style reference): !`git log --oneline -10`

## Your task

**Step 1 — Plan only. No git commands yet.**
Analyse the diff and produce an explicit commit plan: a numbered list where each entry shows the commit message and the exact files it covers. Split as finely as possible (see grouping strategy below).

Output the plan, then end your turn with a confirmation question such as "Does this plan look good?". **Do not run any `git add` or `git commit` command in this step.** Your response must contain only the plan and the question — no tool calls that modify the repo.

**Step 2 — Execute after approval.**
Only once the user has explicitly approved the plan (e.g. "yes", "go ahead", "ok"), execute each commit in the listed order without asking for confirmation again. Stage only the files for each commit, commit, then move to the next. The project must compile after each individual commit.

---

## Conventional Commits format

```
<type>(<scope>): <subject>
```

- **Subject**: imperative, present tense ("add" not "added"), no capital first letter, no trailing dot.
- **Scope**: the component or area affected (feature or layer name). Optional but encouraged; keep it short and consistent.
- **Body** (optional): explain the *why*, not the *what*. Wrap at a readable width.
- **English only**.

### Authorship — no AI attribution

Commits are owned by their human author. **Never** add `Co-Authored-By` trailers for AI assistants, `🤖 Generated with` footers, or any "assisted by" mention.

### Types

| Type       | When to use                                                            |
| ---------- | ---------------------------------------------------------------------- |
| `feat`     | New user-facing functionality                                          |
| `fix`      | Bug fix                                                                |
| `ui`       | Visible UI change that is **not** a new feature (layout, icon, color)  |
| `refactor` | Internal restructuring with **no** visible change                      |
| `perf`     | Code change that improves performance, with no other behavior change   |
| `style`    | Formatting only (linter/formatter), no behavior change                 |
| `docs`     | Documentation only                                                     |
| `test`     | Tests only                                                             |
| `build`    | Build system, dependencies, schema/migration files                     |
| `chore`    | Miscellaneous maintenance                                              |
| `ci`       | CI/CD pipeline changes                                                 |

---

## Grouping strategy — split as finely as possible

Group files by **layer** and by **feature**. One layer + one feature = one commit. Never mix a refactor with a feature, or business logic with resources.

Suggested order (each is a separate commit when it has changes):

1. `build(...)` — build scripts, dependency catalogs, schema/migration files
2. `feat`/`refactor(<feature>)` — domain layer: entities, value types, repository interfaces
3. `feat`/`refactor(<feature>)` — data layer: repository implementations, persistence
4. `feat`/`refactor(<feature>)` — navigation / routing
5. `feat`/`ui(<feature>)` — screens, composables, string resources
6. `feat`/`refactor(<feature>)` — top-level wiring

If multiple independent features change in the same layer, split further: one commit per feature per layer.

### Example of good atomic commits

```
build(settings): add user preferences schema and migration
feat(settings): add Theme and UserPreferences domain types
feat(settings): implement preferences repository
feat(settings): add settings route and router
feat(settings): add settings screen with string resources
```

---

## Rules

- Stage **only** the files for the current commit: `git add <specific-files>`, never `git add .` or `git add -A`.
- Verify compilability before each commit when the change is non-trivial.
- After all commits, run `git status` to confirm nothing is left unstaged.
