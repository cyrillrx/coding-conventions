# Issue Labels

A backlog is only worth ordering if every ticket is scored the same way. This document puts the scores of [Code Review Triage](code-review-triage.md) on the ticket itself, as labels, so an open issue can be filtered and ordered without being reopened and read.

It applies to every ticket in a GitHub tracker: a 🕐 follow-up carries the scores its triage already gave it, and a ticket born anywhere else — a bug report, a feature request, an idea — is scored on the same scales when it is filed.

## 1. Three families, one label each

A ticket carries exactly one label of each family. The scales are those of [Code Review Triage](code-review-triage.md) §2 to §4, which own the definitions — they are not restated here.

| Family       | Labels                                                                 | Scale                                                       |
|--------------|------------------------------------------------------------------------|-------------------------------------------------------------|
| `severity`   | `severity:blocker`, `severity:major`, `severity:minor`, `severity:nit` | [Severity](code-review-triage.md#2-severity)                |
| `impact`     | `impact:functional`, `impact:technical`, `impact:both`                 | [Impact](code-review-triage.md#3-impact)                    |
| `complexity` | `complexity:S`, `complexity:M`, `complexity:L`                         | [Complexity](code-review-triage.md#4-complexity-to-address) |

The fourth triage axis has no label: an open ticket is a 🕐 by definition, and closing it as ❌ says the rest.

No type label either. The title already carries the type as its Conventional Commits prefix (`fix(…)`, `feat(…)`, `refactor(…)`), and a label would repeat it.

## 2. Scoring a ticket

- **A follow-up** keeps the scores of the triage that deferred it. Rescore only when the code has moved since.
- **A defect found outside a review** is scored as if the change that introduced it were under review now. `severity:blocker` is a crash, data loss or security hole reachable in normal use; the same defect reachable only from a corrupted state or a hand-edited file is `severity:major`.
- **A feature** has no consequence of shipping, so its severity reads as the cost to users of going without it: `major` when they cannot complete a task the product is for, `minor` when they can by a detour, `nit` when it is a nicety.
- **Complexity** is the cost of the ticket as its own PR: the diff column of §4 is read against the 200 lines / 10 files budget of a fresh PR, not of the one that found it. An `L` is split into tickets before anyone starts on it.

A ticket missing any of the three labels has not been triaged yet.

## 3. Reading the backlog

Order by severity first, then complexity: a `severity:major` `complexity:S` comes before a `severity:major` `complexity:L`, and both before any `severity:minor`. Impact does not change the order; it tells who is waiting on the fix.

On GitHub, `label:severity:major label:complexity:S` in the issue search gives the next quick wins.

## 4. Setting up a repository

Colours follow the severity emojis, so a label reads the same as the triage table:

```bash
gh label create "severity:blocker"  --color b60205 --description "🔴 Crash, data loss or security hole reachable in normal use"
gh label create "severity:major"    --color e67e22 --description "🟠 Wrong behavior, edge cases included; broken contract; significant perf cost"
gh label create "severity:minor"    --color fbca04 --description "🟡 Maintainability or convention issue, no behavior change"
gh label create "severity:nit"      --color 1d76db --description "🔵 Preference or cosmetics"
gh label create "impact:functional" --color d4c5f9 --description "Borne by users"
gh label create "impact:technical"  --color c2e0c6 --description "Borne by developers"
gh label create "impact:both"       --color 8fbcbb --description "Borne by users and developers"
gh label create "complexity:S"      --color bfdadc --description "Minutes; a few lines"
gh label create "complexity:M"      --color 5ab0c8 --description "Hours; tens of lines or one or two new files"
gh label create "complexity:L"      --color 1d4e89 --description "A day or more; many files, a new area or an ADR"
```

GitHub's default `bug` and `enhancement` labels duplicate the title prefix: delete them, or leave them unused.
