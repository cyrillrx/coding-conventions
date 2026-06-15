---
name: sync-plugins
description: Regenerate the marketplace plugin skills from the convention docs. Run after editing any file in collaboration/ or conventions/.
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash(git status:*)
  - Bash(git diff:*)
---

# Sync plugins from conventions

This repository keeps two layers in sync:

- **Source of truth** — the human-readable convention docs in `collaboration/` and `conventions/`. They never depend on AI tooling.
- **Derived artifacts** — the Claude Code plugin skills under `plugins/`, distilled from those docs.

When a convention doc changes, the derived skills must be regenerated so the plugins stay faithful to the docs. This skill does that regeneration; it is the only sanctioned way to edit the generated parts of the skills.

## Source → derived mapping

| Source doc(s)                                                          | Derived skill                                            | What is derived                                              |
| ---------------------------------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------- |
| `collaboration/git-and-collaboration.md`                               | `plugins/git-workflow/skills/commit/SKILL.md`            | Commit format, types table, authorship rule, grouping       |
| `collaboration/git-and-collaboration.md`                               | `plugins/git-workflow/skills/address-review/SKILL.md`    | Triage criteria, authorship rule in the commit step         |
| `conventions/kmp-conventions.md`, `conventions/coding-conventions.md`  | `plugins/kmp-conventions/skills/kmp-style/SKILL.md`      | The entire knowledge body                                   |
| _not yet created_ — `conventions/rust-conventions.md`                  | `plugins/rust-conventions/` (to create)                  | —                                                           |
| _not yet created_ — `conventions/go-conventions.md`                    | `plugins/go-conventions/` (to create)                    | —                                                           |
| _not yet created_ — `conventions/bruno-conventions.md`                 | `plugins/bruno-conventions/` (to create)                 | —                                                           |

## Procedure

1. Run `git diff` (and `git status`) to see which convention docs changed since the last sync.
2. For each changed source doc, open the derived skill(s) from the mapping above.
3. Regenerate **only the derived content** — the convention rules, format tables, and knowledge body — to match the current docs. **Preserve the skill-specific mechanics** that are not in the docs: the frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`), the workflow steps (plan-then-execute, GraphQL triage flow), and the generated-from header comment.
4. Each derived `SKILL.md` keeps its header comment naming its source doc(s) and pointing back to `/sync-plugins`.
5. If a new convention doc has no plugin yet (rust/go/bruno), either create the plugin (manifest under `.claude-plugin/plugin.json`, skill under `skills/<name>/SKILL.md`, and an entry in `.claude-plugin/marketplace.json`) or leave it — note the decision to the user.
6. Show the resulting `git diff` for the regenerated skills and ask the user to review before committing. Do not commit.

## Notes

- Never invent rules not present in the source docs. If a doc is ambiguous, ask rather than guess.
- If a skill's mechanics need to change (not just its convention content), that is a manual edit — flag it explicitly rather than silently rewriting it here.
