# Tech team guidelines

Coding conventions and collaboration guidelines, shared across projects. These documents are the human-readable source of truth — they stand on their own, independently of any tooling.

## Collaboration

- [Git & Collaboration](collaboration/git-and-collaboration.md) — Conventional Commits, branching, PR etiquette, ADRs
- [Code Review Comments](collaboration/code-review-comments.md) — emoji legend for review comments, and how to answer them
- [Code Review Triage](collaboration/code-review-triage.md) — turning findings into decisions: severity, impact, complexity, recommendation
- [Pull Request Descriptions](collaboration/pull-request-descriptions.md) — keeping a title and description true to the diff as the branch moves
- [Project Audit](collaboration/project-audit.md) — grading a project's health over time: scope, axes, severities, state and effort grades

## Conventions

- [General Coding Conventions](conventions/coding-conventions.md) — Clean Code principles (all languages)
- [Documentation Conventions](conventions/docs-conventions.md) — file naming, section separators, line wrapping, Markdown tables
- [Kotlin](conventions/kotlin-conventions.md) — style, idioms, testing, multiplatform (any Kotlin project)
- [Compose](conventions/compose-conventions.md) — UI architecture, Compose, end-to-end tests (Android / KMP / CMP apps)
- [Rust Backend](conventions/rust-conventions.md)
- [Go Backend](conventions/go-conventions.md)
- [Bruno API Testing](conventions/bruno-conventions.md)

## Shared configs

- [`configs/.editorconfig`](configs/.editorconfig) — editor settings for every project (UTF-8, LF, final newline, no trailing whitespace), plus the ktlint configuration for Kotlin; copy it to the project root
- [`.github/pull_request_template.md`](.github/pull_request_template.md) — PR description template; copy it into a project's own `.github/`

## Templates

Document skeletons to copy into a project when writing a new one. Guidance is in HTML comments — delete them once the document is written.

- [`templates/adr-template.md`](templates/adr-template.md) — Architecture Decision Record; copy to the project's `docs/adr/` as `adr-NNN-kebab-case-title.md`
- [`templates/prd-template.md`](templates/prd-template.md) — Product Requirement Document; copy to the project's `docs/prd/` as `prd-NNN-kebab-case-title.md`

## Claude Code plugins

These conventions are also published as a [Claude Code](https://claude.com/claude-code) plugin marketplace, so they can be installed as reusable skills in any project. The docs above stay the source of truth; the plugin skills are **derived** from them (regenerated with the repo-local `/sync-plugins` skill).

Marketplace name: **`cyrillrx-conventions`**. Available plugins:

| Plugin                | Skills                                                            | What it does |
| --------------------- | ----------------------------------------------------------------- | --- |
| `git-workflow`        | `/commit`, `/pull-request`, `/triage-findings`, `/address-review` | Atomic Conventional Commits; PR descriptions kept in line with their diff; review-finding triage; answering reviewer comments |
| `kotlin-conventions`  | — (SessionStart hook)                                             | Points every session to the Kotlin conventions; pair it with `coding-conventions` for Clean Code |
| `compose-conventions` | — (SessionStart hook)                                             | Points every session to the Compose UI conventions; enable it with `kotlin-conventions` in an app with screens |
| `coding-conventions`  | — (SessionStart hook)                                             | Loads the general coding and documentation conventions into every session |

### Install in a project

One-off, from any project in Claude Code:

```
/plugin marketplace add cyrillrx/coding-conventions
/plugin install git-workflow@cyrillrx-conventions
```

For a team project, commit this to the project's `.claude/settings.json` so the plugins install on trust:

```json
{
  "extraKnownMarketplaces": {
    "cyrillrx-conventions": {
      "source": { "source": "github", "repo": "cyrillrx/coding-conventions" }
    }
  },
  "enabledPlugins": {
    "git-workflow@cyrillrx-conventions": true,
    "kotlin-conventions@cyrillrx-conventions": true,
    "compose-conventions@cyrillrx-conventions": true,
    "coding-conventions@cyrillrx-conventions": true
  },
  "permissions": {
    "allow": ["Read(~/.claude/plugins/cache/cyrillrx-conventions/**)"]
  }
}
```

Enable `compose-conventions` only in a project with screens: a server or a library leaves it out. The `permissions` rule lets the agent read the Kotlin and Compose conventions without a prompt: their hooks point to files in the plugin cache, outside the project folder. Without it, every session asks for that read, and a non-interactive `claude -p` run is refused it and works without the conventions.

> **Heads up:** `enabledPlugins` installs and enables these plugins for anyone who trusts the project folder, without an explicit `/plugin install` prompt. Only commit this once your team is comfortable trusting `cyrillrx/coding-conventions` as a code source — the skills can run git and `gh` commands on contributors' machines.

The plugins are **derived** from the convention docs and regenerated regularly, so they intentionally carry no version: a given install tracks the marketplace repo's `main` at the time `/plugin marketplace add` (or its auto-update) runs. Re-run `/plugin marketplace update cyrillrx-conventions` to pull the latest skills.
