# AGENTS.md

This file provides guidance to AI agents working in this repository.

## Purpose

Documentation-only repository containing coding conventions and collaboration guidelines for a mobile tech team. There is no build system, no tests, and no runnable code — all files are Markdown.

## Structure

```
README.md                      # Index linking to all documents
guidelines-PRs-and-commits.md # Commit format, PR rules for authors and reviewers
code-review-emojis.md          # Emoji legend for code review comments
android/
  README.md                    # Index for Android docs
  IDE-setup.md                 # Android Studio configuration steps
  code-style.md                # Kotlin/Compose style guide
```

## Commit message format

All commits follow this structure:

```
[Type] ISSUE-ID - Short title (verb in infinitive, ≤70 chars)

Description hard-wrapped at 70 columns.

Resolves: ISSUE-ID
```

**Types:** `Feat`, `UI`, `Tech`, `Tracking`, `Test`, `Build`, `Docs`, `Fix`

## Conventions in force

### Android (`android/code-style.md`)
- Kotlin only; based on [Kotlin's coding conventions](https://kotlinlang.org/docs/reference/coding-conventions.html)
- Jetpack Compose — no XML layouts, no View system APIs
- 4-space indent, 120-char line limit, trailing commas on multi-param declarations
- Prefer early returns over deep nesting; prefer affirmative conditions
- List state: hoist `LazyListState` when the parent needs to interact with it
- Visibility: bare `if` for show/hide, `AnimatedVisibility` for transitions
- Events: `StateFlow` for UI state, `SharedFlow` for one-shot events (navigation, snackbars)
- Image resources: `ic_` prefix + size suffix for icons, `img_` prefix + size suffix for multicolor images

### Collaboration (`guidelines-PRs-and-commits.md`)
- PRs: ≤200 lines, ≤10 files; exceptions for mechanical changes
- Reviewers must be constructive and back comments with sources
- Use [code-review-emojis.md](code-review-emojis.md) to signal blocking vs. non-blocking comments
