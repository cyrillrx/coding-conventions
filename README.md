# Tech team guidelines

Coding conventions and collaboration guidelines, shared across projects. These documents are the human-readable source of truth — they stand on their own, independently of any tooling.

## Collaboration

- [Git & Collaboration](collaboration/git-and-collaboration.md) — Conventional Commits, branching, PR etiquette, ADRs
- [Code Review Emojis](collaboration/code-review-emojis.md) — emoji legend for review comments

## Conventions

- [General Coding Conventions](conventions/coding-conventions.md) — Clean Code principles (all languages)
- [Documentation Conventions](conventions/docs-conventions.md) — file naming, Markdown tables
- [Kotlin Multiplatform & Compose](conventions/kmp-conventions.md) — architecture, style, testing (Android / KMP / CMP)
- [Rust Backend](conventions/rust-conventions.md)
- [Go Backend](conventions/go-conventions.md)
- [Bruno API Testing](conventions/bruno-conventions.md)

## Shared configs

- [`configs/kotlin/.editorconfig`](configs/kotlin/.editorconfig) — ktlint configuration for Kotlin projects

## Claude Code plugins

These conventions are also published as a [Claude Code](https://claude.com/claude-code) plugin marketplace, so they can be installed as reusable skills in any project. The docs above stay the source of truth; the plugin skills are **derived** from them (regenerated with the repo-local `/sync-plugins` skill).

Marketplace name: **`cyrillrx-conventions`**. Available plugins:

| Plugin            | Skills                       | What it does                                            |
| ----------------- | ---------------------------- | ------------------------------------------------------- |
| `git-workflow`    | `/commit`, `/address-review` | Atomic Conventional Commits; PR review-comment workflow |
| `kmp-conventions` | `kmp-style` (auto-invoked)   | Kotlin Multiplatform / Compose style and architecture  |

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
    "kmp-conventions@cyrillrx-conventions": true
  }
}
```

> **Heads up:** `enabledPlugins` installs and enables these plugins for anyone who trusts the project folder, without an explicit `/plugin install` prompt. Only commit this once your team is comfortable trusting `cyrillrx/coding-conventions` as a code source — the skills can run git and `gh` commands on contributors' machines.

The plugins are **derived** from the convention docs and regenerated regularly, so they intentionally carry no version: a given install tracks the marketplace repo's `main` at the time `/plugin marketplace add` (or its auto-update) runs. Re-run `/plugin marketplace update cyrillrx-conventions` to pull the latest skills.
