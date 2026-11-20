# Prose Review

A code review hunts for bugs: every line is a claim to test. Pointed at prose, the same review attacks every sentence, each fix adds text for the next round to attack, and the document grows one level below its purpose: invariants, field names, formats, edge-case rules. That detail belongs in the code and its tests, or in the document it comes from, where it is checked, not restated in prose, where it drifts. A review loop that runs a code review over prose does not converge. This document defines how a prose document is reviewed instead: at the level of what it decides or prescribes, in one pass.

Its findings are then scored and decided like any other, per [Code Review Triage](code-review-triage.md).

## 1. What a prose document is

A document written to be read, by a person or an agent, rather than run. It comes in two kinds:

- **A decision document** records a decision and its reasons: an ADR, in `docs/adr/` (see [Git & Collaboration](git-and-collaboration.md#9-architecture-decision-records-adrs) and [`templates/adr-template.md`](../templates/adr-template.md)); a PRD, in `docs/prd/` (see [`templates/prd-template.md`](../templates/prd-template.md)); a spec, or any other document a project's `AGENTS.md` names as one. It is recognized by its path first, and by its shape when the path says nothing: an `ADR-NNN` or `PRD-NNN` title, or the sections of its template.
- **A prescriptive document** tells its reader what to do: a convention, a guide, a README, a skill file (`SKILL.md`), an `AGENTS.md`, a template.

Every other Markdown or text document is one or the other, whichever its purpose is closer to. Comments and KDoc are not prose documents: they are code, and [Coding Conventions](../conventions/coding-conventions.md) governs them.

## 2. The questions

The review answers a fixed set of questions about the document, and nothing else. A decision document gets six:

| Question          | What it asks                                                                         |
|-------------------|--------------------------------------------------------------------------------------|
| **Problem**       | Is the problem stated, with enough context to be understood a year from now?         |
| **Alternatives**  | Are the real options listed, each with the reason it was rejected?                   |
| **Consequences**  | Are they honest about what the decision costs, and about what it does not guarantee? |
| **Reversibility** | Can the decision be undone, and at what price? Is that said?                         |
| **Consistency**   | Does it contradict a PRD, another ADR, or the code it governs?                       |
| **Altitude**      | Does it hold detail that belongs in code or tests?                                   |

For a PRD, the decision is the scope: the alternatives are what the Out of Scope section rules out, and the consequences are what the requirements commit the product to.

A prescriptive document gets five, the same review adapted to a text that prescribes rather than decides:

| Question          | What it asks                                                                                    |
|-------------------|-------------------------------------------------------------------------------------------------|
| **Reason**        | Is each rule stated with its reason, so that a reader can apply it to a case it does not name?  |
| **Consistency**   | Does it contradict itself, the documents it derives from, its siblings, or the code it governs? |
| **Accuracy**      | Is every fact true: a path, a command, a name, a link, a number?                                |
| **Altitude**      | Does it hold detail that belongs in its source document, in code or tests, or nowhere?          |
| **Actionability** | Can its reader do what it asks, as written, without guessing?                                   |

Consistency and accuracy are the whole of correctness on prose: a contradiction or a factual error is a bug in a document, and nothing else in it is.

## 3. A finding changes an answer

**A finding that changes none of the answers is not a finding on the document.** A missing edge case, a field that could be named better, a rule worded loosely: when the decision, its reasons and its costs read the same with or without the fix, or when the reader would act the same, the review does not report it. Its place, if any, is the code review of the implementation.

Every finding names the question whose answer it changes, and what the answer becomes.

## 4. Altitude: flag for removal

A document says what is decided or prescribed, concretely enough to be unambiguous; the ADR template asks for the concrete shape (class names, field names, file layout) when that shape is the decision. Detail goes too far when no alternative turns on it and no reader acts differently for it: a rule invariant, a validation format, the content of a field, the exact behavior of an edge case. That detail is checked by the code and its tests, or owned by another document, and only drifts when restated.

An altitude finding asks for **removal**, never for refinement: the fix is to delete the detail, or to replace it with a pointer to the code, the test or the document that holds it. A prose review should shorten a document more often than lengthen it.

## 5. One pass

A prose document is reviewed once per change, not round after round. The questions above do not converge by iteration: a second pass over the fixes of the first only reviews the wording of the answers, which is the drift this document exists to stop. In a [review loop](code-review-loop.md), the document gets this review in the first round; the conformance review (its template, [docs conventions](../conventions/docs-conventions.md)) still covers it every round. A fix that only rewords the document still gets the two factual questions, consistency and accuracy, in the round that follows: a wrong path or a new contradiction is a bug, and facts converge where wording does not.

A fix that changes what the document decides or prescribes (another option chosen, a consequence that changes the choice, a rule added, dropped or reversed rather than reworded) makes it a new document: it gets one more pass, alone. In a review loop, it is the round that follows, with the same review, without leaving the loop.

## 6. Changes that mix code and prose

A pull request that changes code often edits a document too. The review is chosen per file, not per pull request:

- **Each file gets its own review.** A prose document gets this one, the code gets a code review; a change holding both gets both, each on its files. A code review finding anchored in a prose document is not reported; one anchored in the code stays, including when it cites the document: code that departs from its decision or its convention is a real finding.
- **A document edited along the way is reviewed on its diff, once.** An addition that only refines the document (an invariant, a format, a field name settled while implementing) is an altitude finding: it is removed, not reworded. This is where the drift starts.
- **When the code and the document disagree, fix whichever is wrong.** Aligning the document on the code changes what it decides or prescribes: it is a new document, reviewed as one.

## 7. Expected output

One block per finding, in the order of the questions:

```markdown
### 1. Alternatives: `docs/adr/adr-012-sync-engine.md`, "Alternatives considered"

- **Changes**: the answer becomes "no": CRDT-based sync was evaluated in #64 and is not listed
- **Asks for**: add the option with the reason it lost
```

Then the findings go to triage like any other. A review that finds nothing says so, with the answers in one line each: a document that holds is a result, not an absence of one.
