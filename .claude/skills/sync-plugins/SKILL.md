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
  - Bash(git ls-files:*)
  - Bash(claude plugin validate:*)
---

# Sync plugins from conventions

This repository keeps two layers in sync:

- **Source of truth** — the human-readable convention docs in `collaboration/` and `conventions/`. They never depend on AI tooling.
- **Derived artifacts** — the Claude Code plugin skills under `plugins/`, distilled from those docs.

When a convention doc changes, the derived skills must be regenerated so the plugins stay faithful to the docs. This skill does that regeneration; it is the only sanctioned way to edit the generated parts of the skills.

## Source → derived mapping

| Source doc(s)                                                                 | Derived skill                                                    | What is derived |
|-------------------------------------------------------------------------------|------------------------------------------------------------------|---|
| `collaboration/git-and-collaboration.md`                                      | `plugins/git-workflow/skills/commit/SKILL.md`                    | Commit format, types table, authorship rule, grouping |
| `collaboration/git-and-collaboration.md`                                      | `plugins/git-workflow/skills/address-review/SKILL.md`            | The authorship rule in the commit step |
| `collaboration/code-review-comments.md`                                       | `plugins/git-workflow/skills/address-review/SKILL.md`            | The five response outcomes and their criteria, the rationale column, reply tone per response, and which threads get resolved. It does not score: that stays with `triage-findings` |
| `collaboration/code-review-triage.md`                                         | `plugins/git-workflow/skills/triage-findings/SKILL.md`           | Four axes, severity/impact/complexity scales, decision grid and overrides, follow-up ownership rules |
| `collaboration/code-review-triage.md` (§6 and §7)                             | `plugins/git-workflow/skills/address-review/SKILL.md`            | Deferral ownership and trace, the escalation to `triage-findings`. It does not score, so it carries neither the scales nor the grid. |
| `collaboration/pull-request-descriptions.md`, `git-and-collaboration.md` (§7) | `plugins/git-workflow/skills/pull-request/SKILL.md`              | The diff-of-record rules, the two-way reconciliation, the section lifecycle, the title rules, and the template's section list. It does not score findings; the 🔁 section only records what `triage-findings` decided. |
| `collaboration/code-review-loop.md`                                           | `plugins/git-workflow/skills/review-loop/SKILL.md`               | Round 0, the round, the stop conditions and the cap, the closing order, the status labels. It does not score findings nor word replies: it calls `triage-findings` and `address-review` for that. |
| `conventions/kotlin-conventions.md`                                           | `plugins/kotlin-conventions/conventions/kotlin-conventions.md`   | A verbatim copy the plugin's SessionStart hook points the agent to, rather than prints: it exceeds what a hook can inject (see Notes). `coding-conventions.md` comes from the `coding-conventions` plugin, which the plugin descriptions tell users to pair it with |
| `conventions/compose-conventions.md`                                          | `plugins/compose-conventions/conventions/compose-conventions.md` | A verbatim copy, pointed to the same way. It builds on `kotlin-conventions.md`, which comes from the `kotlin-conventions` plugin, never from a second copy here |
| `conventions/coding-conventions.md`                                           | `plugins/coding-conventions/conventions/coding-conventions.md`   | A verbatim copy, injected by the plugin's SessionStart hook: the installed plugin cannot read files outside its own folder |
| `conventions/docs-conventions.md`                                             | `plugins/coding-conventions/conventions/docs-conventions.md`     | A verbatim copy, injected by the same hook |
| `collaboration/project-audit.md`                                              | `plugins/project-health/skills/audit/SKILL.md`                   | Derived: the scope rules, the severity table and both grade grids are copied verbatim, the rest is restated as the skill's steps; keep the grid version in step |
| `conventions/{kotlin,go,rust}-conventions.md`                                 | `plugins/project-health/skills/audit/SKILL.md`                   | By link only: the "latest stable" language line each doc carries, used as the obsolescence reference until a dedicated toolchain policy replaces it |
| _not yet created_ — `conventions/rust-conventions.md`                         | `plugins/rust-conventions/` (to create)                          | — |
| _not yet created_ — `conventions/go-conventions.md`                           | `plugins/go-conventions/` (to create)                            | — |
| _not yet created_ — `conventions/bruno-conventions.md`                        | `plugins/bruno-conventions/` (to create)                         | — |

Beyond its verbatim copy above, `conventions/docs-conventions.md` governs every Markdown file in the repository — step 2 of the procedure covers that.

## Procedure

1. Run `git diff` (and `git status`) to see which convention docs changed since the last sync.
2. For each changed source doc, open the derived skill(s) from the mapping above. If `conventions/docs-conventions.md` changed, also re-check every Markdown file in the repository (`git ls-files '*.md'`) against its current rules, and fix what no longer complies. Its rules govern how every `.md` file is written, derived or not — repo-local skills, `AGENTS.md` and `README.md` included — so its mapping row alone does not cover it.
3. Regenerate **only the derived content** — the convention rules, format tables, and knowledge body — to match the current docs. **Preserve the skill-specific mechanics** that are not in the docs: the frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`), the workflow steps (plan-then-execute, GraphQL triage flow), and the generated-from header comment.
4. Each derived `SKILL.md` keeps its header comment naming its source doc(s) and pointing back to `/sync-plugins`.
5. **A rule may be derived into as many skills as need it** — that is what derivation is for, and this procedure keeps the copies in step. What must never happen is a skill carrying a rule no doc owns, or one whose source is not declared in the mapping above: an undeclared derivation is never regenerated, and that is how two skills drift apart. Skills are told apart by their data source and their action perimeter, not by which rules they restate.
6. If a new convention doc has no plugin yet (rust/go/bruno), either create the plugin (manifest under `.claude-plugin/plugin.json`, skill under `skills/<name>/SKILL.md`, and an entry in `.claude-plugin/marketplace.json`) or leave it — note the decision to the user.
7. If the set of plugins or skills changed (one added, removed, or renamed), update the plugin table in `README.md`, the structure block in `AGENTS.md`, the `keywords` **and** `description` in the plugin's `plugin.json`, and the plugin `description` in `.claude-plugin/marketplace.json` — all five are maintained by hand and drift silently. The two descriptions say the same thing in two files: `plugin.json` is what Claude Code shows for the installed plugin, `marketplace.json` what it shows in the listing.
8. Validate the result with `claude plugin validate .` — it must pass (the advisory `version` warnings, one per plugin, are intentional and expected).
9. Show the resulting `git diff` for the regenerated skills and ask the user to review before committing. Do not commit.

## Notes

- Claude Code injects at most 10,000 characters per SessionStart hook command, and truncates the rest to a short preview. A copy above that limit is pointed to rather than printed, as `kotlin-conventions` and `compose-conventions` do; check a copy's size whenever its source grows.
- A verbatim copy is verbatim except for its relative links: rewrite each one to an absolute `https://github.com/cyrillrx/coding-conventions/blob/main/<path>` URL. The installed plugin holds only its own folder, so a relative link points to nothing. A rewritten link widens its table cell: realign any table it sits in, as `conventions/docs-conventions.md` measures alignment.
- Never invent rules not present in the source docs. If a doc is ambiguous, ask rather than guess.
- If a skill's mechanics need to change (not just its convention content), that is a manual edit — flag it explicitly rather than silently rewriting it here.
