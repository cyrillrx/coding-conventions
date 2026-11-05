---
name: review-decision
description: >-
  Review a decision document (ADR, PRD, spec) at the level of what it decides, in one pass: problem,
  alternatives, consequences, reversibility, consistency, and altitude (detail that belongs in code or
  tests, flagged for removal). Reports findings only, each naming the answer it changes; it edits
  nothing and decides nothing. Use instead of a code review when the change is, or includes, an ADR,
  a PRD or a spec.
argument-hint: "[path...]"
# Read-only: this skill reports findings. Scoring them belongs to triage-findings.
allowed-tools:
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git log:*)
  - Bash(git branch --show-current:*)
  - Bash(git symbolic-ref:*)
  - Read
  - Grep
  - Glob
---

<!--
The six questions, the finding rule, the altitude rule and the one-pass rule are derived from
collaboration/decision-document-review.md in cyrillrx/coding-conventions. Keep them in sync with
/sync-plugins.
-->

## Context

- Arguments: $ARGUMENTS
- Current branch: !`git branch --show-current`

## Your task

Review decision documents at the level of the decision, and report findings. A code review attacks every sentence of a document, and each fix gives the next round more to attack: the document grows one level below its decision, with invariants, field names and formats that the code and its tests should hold instead. This review asks six questions, once, and reports only what changes their answers.

### Step 1: Find the documents

- With paths in the arguments, review those.
- Otherwise, take the decision documents the branch changes. Resolve the base branch with `git symbolic-ref --short refs/remotes/origin/HEAD` (ask if it is missing or the project targets another branch), then list `git diff --name-only <base>...HEAD`, plus uncommitted changes from `git status --short`.

A decision document records a decision and its reasons: an ADR (`docs/adr/`), a PRD (`docs/prd/`), a spec, or any document the project's `AGENTS.md` names as one. A README, a guide or a convention document is not one. If no decision document is found, say so and stop: this skill does not review code.

### Step 2: Read around each document

Read the document in full, then what it must be consistent with: the ADRs and PRDs it links, the others in its folder whose subject overlaps, and the code it governs where the branch touches it. For a document the branch modifies, read its diff too, but review the document as it now stands.

### Step 3: Answer the six questions

| Question          | What it asks                                                                         |
|-------------------|--------------------------------------------------------------------------------------|
| **Problem**       | Is the problem stated, with enough context to be understood a year from now?         |
| **Alternatives**  | Are the real options listed, each with the reason it was rejected?                   |
| **Consequences**  | Are they honest about what the decision costs, and about what it does not guarantee? |
| **Reversibility** | Can the decision be undone, and at what price? Is that said?                         |
| **Consistency**   | Does it contradict a PRD, another ADR, or the code it governs?                       |
| **Altitude**      | Does it hold detail that belongs in code or tests?                                   |

For a PRD, the decision is the scope: the alternatives are what the Out of Scope section rules out, and the consequences are what the requirements commit the product to.

**A finding that changes none of the six answers is not a finding on the document.** A missing edge case, a field that could be named better, a rule worded loosely: when the decision, its reasons and its costs read the same with or without the fix, do not report it. Its place, if any, is the code review of the implementation.

**Altitude findings ask for removal, never for refinement.** A document states what is decided, concretely enough to be unambiguous, and the concrete shape (class names, field names, file layout) stays when that shape is the decision. Detail goes too far when no alternative turns on it: a rule invariant, a validation format, the content of a field, the exact behavior of an edge case. The fix is to delete it, or to replace it with a pointer to the code or test that holds it. Expect this review to shorten a document more often than lengthen it.

### Step 4: Report

One block per finding, in the order of the six questions:

```markdown
### 1. Alternatives: `docs/adr/adr-012-sync-engine.md`, "Alternatives considered"

- **Changes**: the answer becomes "no": CRDT-based sync was evaluated in #64 and is not listed
- **Asks for**: add the option with the reason it lost
```

When a document holds, say so, with the six answers in one line each: that is a result, not an absence of one.

End by pointing to `/git-workflow:triage-findings` to score and decide the findings. Do not edit the document.

## Rules

- One pass. Do not review your own earlier findings or their fixes again: a second pass over the answers only reviews their wording, which is the drift this review exists to stop. A fix that changes the decision itself is a new decision, reviewed again on its own.
- Every finding names the question whose answer it changes, and what the answer becomes.
- Never propose adding implementation detail to a decision document.
- Report, never edit, never decide: scoring is `triage-findings`' job.
