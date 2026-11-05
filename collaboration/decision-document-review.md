# Decision Document Review

A code review hunts for bugs: every line is a claim to test. Pointed at a decision document, the same review attacks every sentence, each fix adds text for the next round to attack, and the document grows one level below its decision: invariants, field names, formats. That detail belongs in the code and its tests, where it is checked, not in prose, where it drifts. This document defines how a decision document is reviewed instead: at the level of what it decides, in one pass.

Its findings are then scored and decided like any other, per [Code Review Triage](code-review-triage.md).

## 1. What a decision document is

A document whose purpose is to record a decision and its reasons, rather than to explain how something works:

- an ADR, in `docs/adr/` (see [Git & Collaboration](git-and-collaboration.md#9-architecture-decision-records-adrs) and [`templates/adr-template.md`](../templates/adr-template.md));
- a PRD, in `docs/prd/` (see [`templates/prd-template.md`](../templates/prd-template.md));
- a spec, or any other document a project's `AGENTS.md` names as one.

A README, a guide or a convention document is not one: it describes, and a regular review applies.

## 2. Six questions

The review answers six questions about the document, and nothing else:

| Question          | What it asks                                                                         |
|-------------------|--------------------------------------------------------------------------------------|
| **Problem**       | Is the problem stated, with enough context to be understood a year from now?         |
| **Alternatives**  | Are the real options listed, each with the reason it was rejected?                   |
| **Consequences**  | Are they honest about what the decision costs, and about what it does not guarantee? |
| **Reversibility** | Can the decision be undone, and at what price? Is that said?                         |
| **Consistency**   | Does it contradict a PRD, another ADR, or the code it governs?                       |
| **Altitude**      | Does it hold detail that belongs in code or tests?                                   |

For a PRD, the decision is the scope: the alternatives are what the Out of Scope section rules out, and the consequences are what the requirements commit the product to.

## 3. A finding changes an answer

**A finding that changes none of the six answers is not a finding on the document.** A missing edge case, a field that could be named better, a rule worded loosely: when the decision, its reasons and its costs read the same with or without the fix, the review does not report it. Its place, if any, is the code review of the implementation.

Every finding names the question whose answer it changes, and what the answer becomes.

## 4. Altitude: flag for removal

A document says what is decided, concretely enough to be unambiguous; the ADR template asks for the concrete shape (class names, field names, file layout) when that shape is the decision. Detail goes too far when no alternative turns on it: a rule invariant, a validation format, the content of a field, the exact behavior of an edge case. That detail is checked by the code and its tests, and only drifts in prose.

An altitude finding asks for **removal**, never for refinement: the fix is to delete the detail, or to replace it with a pointer to the code or the test that holds it. A review of a decision document should shorten it more often than lengthen it.

## 5. One pass

A decision document is reviewed once per change, not round after round. The questions above do not converge by iteration: a second pass over the fixes of the first only reviews the wording of the answers, which is the drift this document exists to stop. In a [review loop](code-review-loop.md), the document is reviewed in the first round only; the conformance review (its template, [docs conventions](../conventions/docs-conventions.md)) still covers it every round.

A fix that changes the decision itself (another option chosen, a consequence that changes the choice) is a new decision: it is reviewed again, on its own.

## 6. Expected output

One block per finding, in the order of the six questions:

```markdown
### 1. Alternatives: `docs/adr/adr-012-sync-engine.md`, "Alternatives considered"

- **Changes**: the answer becomes "no": CRDT-based sync was evaluated in #64 and is not listed
- **Asks for**: add the option with the reason it lost
```

Then the findings go to triage like any other. A review that finds nothing says so, with the six answers in one line each: a document that holds is a result, not an absence of one.
