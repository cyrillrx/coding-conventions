---
name: review-prose
description: >-
  Review a prose document at the level of what it decides or prescribes, in one pass: a decision
  document (ADR, PRD, spec) on its problem, alternatives, consequences, reversibility, consistency and
  altitude; a convention, guide, README or skill file on its reasons, consistency, accuracy, altitude
  and actionability. Reports findings only, each naming the answer it changes; it edits nothing and
  decides nothing. Use instead of a code review whenever the change is, or includes, a prose document.
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
The two kinds of prose document, the questions, the finding rule, the altitude rule, the one-pass
rule and the mixed-change rules are derived from collaboration/prose-review.md in
cyrillrx/coding-conventions.
Keep them in sync with /sync-plugins.
-->

## Context

- Arguments: $ARGUMENTS
- Current branch: !`git branch --show-current`

## Your task

Review prose documents at the level of what they decide or prescribe, and report findings. A code review attacks every sentence of a document, and each fix gives the next round more to attack: the document grows one level below its purpose, with invariants, formats and edge-case rules that the code, its tests or another document should hold instead. This review asks a fixed set of questions, once, and reports only what changes their answers.

### Step 1: Find the documents

- With paths in the arguments, review those.
- Otherwise, take the prose documents the branch changes. Resolve the base branch with `git symbolic-ref --short refs/remotes/origin/HEAD` (ask if it is missing or the project targets another branch), then list `git diff --name-only <base>...HEAD`, plus uncommitted changes from `git status --short`.

A prose document is written to be read rather than run, and comes in two kinds:

- **A decision document** records a decision and its reasons: an ADR (`docs/adr/`), a PRD (`docs/prd/`), a spec, or any document the project's `AGENTS.md` names as one. When the path says nothing, recognize it by its shape: an `ADR-NNN` or `PRD-NNN` title, or the sections of the project's ADR or PRD template.
- **A prescriptive document** tells its reader what to do: a convention, a guide, a README, a skill file (`SKILL.md`), an `AGENTS.md`, a template.

Any other Markdown or text document is one or the other, whichever its purpose is closer to. Comments and KDoc are code. If no prose document is found, say so and stop: this skill does not review code. In a change that also holds code, review only the documents: the code goes to a code review, and is read here only to check consistency.

### Step 2: Read around each document

Read the document in full, then what it must be consistent with: the documents it links or derives from (a derived skill names its source), the others in its folder whose subject overlaps, and the code it governs where the branch touches it. For a document the branch modifies, read its diff too, but review the document as it now stands.

### Step 3: Answer the questions

A decision document gets six:

| Question          | What it asks                                                                         |
|-------------------|--------------------------------------------------------------------------------------|
| **Problem**       | Is the problem stated, with enough context to be understood a year from now?         |
| **Alternatives**  | Are the real options listed, each with the reason it was rejected?                   |
| **Consequences**  | Are they honest about what the decision costs, and about what it does not guarantee? |
| **Reversibility** | Can the decision be undone, and at what price? Is that said?                         |
| **Consistency**   | Does it contradict a PRD, another ADR, or the code it governs?                       |
| **Altitude**      | Does it hold detail that belongs in code or tests?                                   |

For a PRD, the decision is the scope: the alternatives are what the Out of Scope section rules out, and the consequences are what the requirements commit the product to.

A prescriptive document gets five:

| Question          | What it asks                                                                                    |
|-------------------|-------------------------------------------------------------------------------------------------|
| **Reason**        | Is each rule stated with its reason, so that a reader can apply it to a case it does not name?  |
| **Consistency**   | Does it contradict itself, the documents it derives from, its siblings, or the code it governs? |
| **Accuracy**      | Is every fact true: a path, a command, a name, a link, a number?                                |
| **Altitude**      | Does it hold detail that belongs in its source document, in code or tests, or nowhere?          |
| **Actionability** | Can its reader do what it asks, as written, without guessing?                                   |

Consistency and accuracy are the whole of correctness on prose: a contradiction or a factual error is a bug in a document, and nothing else in it is.

**A finding that changes none of the answers is not a finding on the document.** A missing edge case, a field that could be named better, a rule worded loosely: when the decision, its reasons and its costs read the same with or without the fix, or when the reader would act the same, do not report it. Its place, if any, is the code review of the implementation.

**A document edited along with the code** is reviewed on its diff. An addition that only refines the document (an invariant, a format, a field name settled while implementing) is an altitude finding: that is where the drift starts. When the code and the document disagree, the finding says which one is wrong; aligning the document on the code changes what it decides or prescribes, and is reviewed as a new document.

**Altitude findings ask for removal, never for refinement.** A document states what is decided or prescribed, concretely enough to be unambiguous, and the concrete shape (class names, field names, file layout) stays when that shape is the decision. Detail goes too far when no alternative turns on it and no reader acts differently for it: a rule invariant, a validation format, the content of a field, the exact behavior of an edge case. The fix is to delete it, or to replace it with a pointer to the code, the test or the document that holds it. Expect this review to shorten a document more often than lengthen it.

### Step 4: Report

One block per finding, in the order of the questions:

```markdown
### 1. Alternatives: `docs/adr/adr-012-sync-engine.md`, "Alternatives considered"

- **Changes**: the answer becomes "no": CRDT-based sync was evaluated in #64 and is not listed
- **Asks for**: add the option with the reason it lost
```

When a document holds, say so, with the answers in one line each: that is a result, not an absence of one.

End by pointing to `/git-workflow:triage-findings` to score and decide the findings. Do not edit the document.

## Rules

- One pass. Do not review your own earlier findings or their fixes again: a second pass over the answers only reviews their wording, which is the drift this review exists to stop. A fix that changes what the document decides or prescribes (another option chosen, a rule added, dropped or reversed rather than reworded) makes it a new document: it gets one more pass, alone (in a review loop, the next round runs it).
- Every finding names the question whose answer it changes, and what the answer becomes.
- Never propose adding implementation detail or an edge-case rule to a prose document.
- Report, never edit, never decide: scoring is `triage-findings`' job.
