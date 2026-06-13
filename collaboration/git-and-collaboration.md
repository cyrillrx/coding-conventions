# Git & Collaboration Conventions

This document outlines the collaboration guidelines, Git conventions, and branching strategy used across projects.
Adhering to these conventions helps maintain a clean, understandable, and traceable project history.

## 1. Collaboration & Communication

- **Respectful Interaction**: All interactions should be respectful and constructive.
- **Clear Communication**: Be clear and concise in your communications (code comments, commit messages, pull request descriptions).
- **Ask Questions**: Don't hesitate to ask questions if something is unclear.

## 2. Conventional Commits

We follow **Conventional Commits** to keep the history clean and to allow automated changelog generation.

A commit message should help reviewers get context around a change, but more importantly it should help investigation when fixing regressions later. A well-written history is the fastest way to spot the origin of a bug from the information it carries.

### Commit Format

```
<type>(<scope>): <subject>

<body>
```

- **Types**: `feat`, `fix`, `ui`, `refactor`, `style`, `docs`, `test`, `chore`, `ci`, `build` (and potentially `perf`, `security`).
  - `feat` — new user-facing functionality
  - `fix` — bug fix
  - `ui` — visible UI change that is not a new feature (e.g. removing an icon, adjusting layout, tweaking a component)
  - `refactor` — internal code restructuring with **no visible change** to the user
  - `style` — formatting only (linter/formatter), no behavior change
  - `docs` — documentation only
  - `test` — adding or fixing tests
  - `chore` — miscellaneous maintenance
  - `ci` — CI/CD pipeline changes
  - `build` — build system, dependencies, schema/migration files
- **Scope**: The component or area affected (e.g. the feature name or layer name). Keep it short and consistent within a project.
- **Subject**: Use the imperative, present tense: "add" not "added" nor "adds". Don't capitalize the first letter. No dot (`.`) at the end.
- **Body** (optional): Explain the *why* and the context, not the *what* (the diff already shows the what). Wrap at a readable width. Reference issue IDs here when relevant (e.g. `Resolves: PROJ-123`).

### Commit Examples

- `feat(campaign): add new campaign creation form`
- `fix(auth): prevent XSS attack in login endpoint`
- `docs(project): update README with new project overview`
- `style(home): format HomeScreen with the configured formatter`
- `ui(spell): remove trailing chevron from spell list item`
- `refactor(server): extract common logging logic to a utility`
- `test(api): add E2E test for user registration flow`
- `build(app): update gradle wrapper to 8.x`

## 3. Trunk-Based Development Branching Strategy

We use a **Trunk-Based Development** branching strategy:

- **Single Main Branch**: All development happens directly on or very close to a single main branch (usually `main`).
- **Small, Frequent Commits**: Commit small changes frequently, often multiple times a day.
- **Short-Lived Feature Branches**: If feature branches are used, keep them very short-lived and merge them back quickly (typically within a day or two). Branch names mirror commit types: `feat/short-description`, `fix/issue-description`, `refactor/short-description`, `docs/short-description`, `chore/short-description` (e.g. `feat/create-campaign`, `fix/login-xss`).
- **Continuous Integration**: A robust CI system automatically builds and tests changes, catching integration issues early.
- **Feature Flags**: Use feature flags to deploy incomplete features without exposing them to users, reducing the need for long-lived branches.

## 4. File Renames

Always use `git mv <old-path> <new-path>` when renaming or moving files. Never delete and recreate.

`git mv` preserves the file's history so that `git log --follow` and `git blame` remain meaningful across renames. A delete+create severs the history chain even when the content is nearly identical.

Apply this to all file types: source files, resource files, data files, documentation, etc.

## 5. Atomic & Incremental Commits

Each commit must be a **single, self-contained logical change**. This makes review easier, enables clean `git bisect` and `git revert`, and keeps the history readable.

- **One commit = one change**: a commit should do one thing — add a component, update a data model, add string resources, etc. Do not mix unrelated changes or changes across different layers in the same commit.
- **Compilable at every commit**: the project must build and all tests must pass after each individual commit.
- **Incremental on feature branches**: progress through small, successive commits a reviewer can validate one by one. Avoid large "big bang" commits.
- **Easy to revert**: an atomic commit can be reverted without side effects on unrelated code.

Good (atomic):
```
feat(spell): add spell level string resources
feat(spell): add SampleSpellRepository with diverse spells
feat(spell): rewrite SpellListItem as compact card
feat(spell): update SpellListScreen to use new SpellListItem
```

Bad (monolithic):
```
feat(spell): redesign spell list screen with new item, samples, and strings
```

## 6. Authorship

Commits and pull requests are owned by their human author, regardless of the tools used to write them. The author is the only author of record.

Do not include AI-generated attribution anywhere in the history or on the platform — no `Co-Authored-By` trailers for AI assistants, no `🤖 Generated with` footers in commit messages or PR descriptions, no "assisted by" mentions. A commit or PR carries the name of the person who is accountable for it; the tooling that helped produce it is not credited.

## 7. Pull Request Etiquette

All commit conventions above also apply to Pull Request titles and descriptions.

**When squashing** commits before merging, do not leave the working commit list as the resulting commit description. Either copy the PR description into the resulting commit's body or rewrite it.

### Authors

- Keep the diff under 200 lines and 10 files when possible. For mechanical changes (renaming, moving files), exceptions are acceptable.
- Proofread your own PR before submitting — check diff, description, and comments.
- Assign reviewers directly on the hosting platform.

### Reviewers

- Review PRs within 24 hours when possible. If you're short on time, don't rush — an unreviewed PR is better than a rubber-stamped one.
- Be constructive and kind: critique the code, not the author.
- Back your comments with sources (docs, articles, benchmarks) rather than personal preference. Avoid arguments from authority. Don't request changes you can't justify.
- Use [Code Review Emojis](code-review-emojis.md) to add meaning to your comments (blocking vs. non-blocking, suggestion vs. question, etc.).

## 8. CI & Policies

- **Pull Requests**: All code must be reviewed via PRs before merging into `main`.
- **Code Quality**: PRs must pass all automated checks (linting, tests, build) on the CI pipeline before they are mergeable.
- **Warnings as Errors**: Treat compiler warnings seriously. Fix them proactively.
- **Security Scans**: Integrate automated security scanning where applicable.

## 9. Architecture Decision Records (ADRs)

For any change that significantly affects the data model, source format, or technical architecture, an **ADR must be created or updated before starting the implementation**.

ADRs follow the naming convention `adr-###-kebab-case-title.md`. Creating the ADR in a dedicated commit (or early in the implementation PR) before the bulk of the implementation gives reviewers context and prevents costly rework.

Changes that typically require an ADR include, but are not limited to:
- Source format or schema changes
- Data distribution format changes (JSON structure, API contracts)
- New cross-cutting architectural patterns (navigation model, deeplink conventions, etc.)
- Database schema changes with migration implications
