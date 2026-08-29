<!--
Copy this file to the project's docs/prd/ as prd-NNN-kebab-case-title.md, then delete every comment.
A PRD describes what a feature does and why, from the user's point of view. It does not describe how it is built — that belongs to an ADR or to the code.
Number 000 is conventionally the product vision; feature PRDs start at 001. A large feature can be split into prd-001a, prd-001b, … rather than growing past a readable length.
-->

# PRD-NNN — <feature name>

> **Status**: Draft | **Version**: 0.1 | **Last updated**: YYYY-MM-DD

<!-- Status: Draft while being written, Approved once agreed, Implemented when shipped, Superseded by PRD-NNN when replaced. Bump the version on every substantive edit — a PRD is a living document, and readers need to know which version they reviewed. -->

## Overview

<!-- What the feature is and who it serves, in a paragraph or two. Link the decisions it depends on (ADRs) and the PRDs it borders, so a reader can tell where this document's scope stops. -->

## Goals

<!-- What success looks like, as outcomes rather than features. Three to five bullets. If a goal cannot be told apart from a requirement below, it is a requirement. -->

## User Stories

<!-- One row per story, in the user's voice. Group by phase when the feature ships in stages. Keep the columns aligned. -->

| As a… | I want to…     | So that…           |
|-------|----------------|--------------------|
| User  | <do something> | <I get some value> |

## Functional Requirements

<!-- What the feature must do, as checkable items. Split into phases when the feature ships incrementally, and keep the checkboxes up to date as work lands — this section doubles as the progress view.
Group related items under a bold sub-heading rather than a flat list of thirty checkboxes. -->

### Phase 1 — MVP

**<Group>**
- [ ] <requirement>

## Non-Functional Requirements

<!-- Constraints that are not features but are still binding: offline behaviour, latency, accessibility, data loss, screen sizes, sync semantics. Write each one so it can be verified. -->

## Out of Scope

<!-- What this PRD deliberately does not cover, and where it goes instead — a future PRD, another feature, or nowhere. Prevents scope creep during implementation and review. -->

## Open Questions

<!-- Decisions still to make, each specific enough to be answerable. Resolve them by linking the ADR or the PRD revision that settled them rather than deleting the line, so the reasoning stays traceable. -->
