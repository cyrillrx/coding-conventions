# Kotlin Conventions

This document details the style rules, idioms and testing guidelines for any Kotlin code: a JVM server, a Kotlin Multiplatform (KMP) library, or the shared modules of an app. The UI layer of an app follows the [Compose conventions](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/compose-conventions.md), which build on this document.

It builds on [Kotlin's coding conventions](https://kotlinlang.org/docs/reference/coding-conventions.html) and the general [Clean Code principles](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/coding-conventions.md).

## Table of Contents

- [Tech Stack & Dependency Management](#tech-stack--dependency-management)
- [Source Code Organization](#source-code-organization)
- [Architecture](#architecture)
- [Naming Rules](#naming-rules)
- [Formatting](#formatting)
- [Code Idioms](#code-idioms)
- [Testing](#testing)
- [Multiplatform](#multiplatform)
- [CI & Policies](#ci--policies)

## Tech Stack & Dependency Management

- **Language**: Kotlin (latest stable version).
- **Dependency Management**:
    - Gradle Version Catalogs (`gradle/libs.versions.toml`) + `buildSrc`.
    - *Never hardcode dependency versions in build scripts.*

## Source Code Organization

### Class layout

Generally, the contents of a class is sorted in the following order:

- Property declarations and initializer blocks
- Secondary constructors
- Method declarations
- Companion object
- Nested classes

For framework classes (e.g. an `Activity`), put framework methods first. Put related stuff together, so that someone reading the class from top to bottom can follow the logic. Higher-level stuff goes first (after framework methods if any).

### Interface implementation layout

When implementing an interface, keep the implementing members in the same order as the members of the interface.

### Overload layout

Always put overloads next to each other in a class.

## Architecture

Code is split **by feature first, then by layer**, following Clean Architecture. Within a feature, **dependencies point toward the domain: presentation → domain ← data.**

```
feature/
  <feature>/
    domain/            models, use cases, the interfaces they depend on, the errors
      inmemory/        the Ram and Sample implementations
    data/              the implementations of the domain's interfaces
    presentation/      screens, ViewModels, the feature's routes and router
core/
  <role>/              generic tools: network, database, designsystem
main/                  the composition root and the navigation graph
```

A layer-first tree spreads each feature over every layer, and only review keeps one feature out of another's data. Feature-first keeps a feature in one place and makes its boundary a path.

### Layers

- **Domain**: Pure Kotlin. Contains entities, use cases, and the interfaces they depend on: the repositories, and any port a repository needs (a store, an API client). The errors its callers branch on are declared here too; a generic result or error type may come from `core`, and the feature declares its own cases. Independent of any framework, it imports neither the data layer nor the presentation layer. Its `inmemory` package holds the [in-memory implementations](#naming-in-memory-repositories).
- **Data**: Implements the interfaces the domain declares. Repositories abstract the data sources. Return Kotlin `Flow` for reactive data streams and `suspend` functions for one-shot operations. Imports the domain and `core`, never the presentation layer.
- **Presentation**: Reaches the data layer through the domain only, and never imports it. A ViewModel calls a use case when there is logic to hold (a rule, several repositories, another feature), and a repository otherwise: a use case that only forwards the call adds a class and no rule. It never calls a parser, a mapper or a file format of the data layer. Previews and ViewModel tests use the domain's `inmemory` implementations.
- **`main`**: The composition root, which builds the data implementations and hands them over, and the navigation graph. It is the only code that imports every feature.

The contract belongs to whoever needs it. An interface declared in the data layer either names a domain type, which makes the data layer define a contract only the domain uses, or invents a failure type of its own that the domain translates a second time. A ViewModel that reaches into the data layer ties the screen to a storage format, and puts logic out of reach of the domain tests.

### Between features

- **A feature uses another through its domain only**, never its data or its presentation.
- **A feature never navigates to another's screen itself.** It exposes its routes, and declares the router its screens take ([Compose conventions](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/compose-conventions.md#navigation-callbacks-in-primary-composables)); `main` implements that router with the other features' routes. A screen that imported another feature's routes would tie the two presentations together, and once split into modules each feature would need a separate routes module for the others to import.
- **Code that names a feature belongs to a feature**, even when others use it: to the domain of the feature that owns it.
- **`core` holds generic tools only**, ones that would work unchanged for a feature that does not exist yet. It is split by role (`network`, `database`, `designsystem`), never `common` or `utils`, and imports no feature.

When a Kotlin server and a Kotlin client share a repository, what both sides must agree on goes in a root `shared` module: the wire types in `contract/<feature>`, and the base they share (a result type, its errors) in `core/`. `shared` says who shares the code, `core` says what it is: one word per meaning keeps `core/` readable inside an app's multiplatform module, conventionally named `shared`, where a `shared/` tools package would give `shared/shared/`.

### Packages first, modules when needed

The boundaries are **packages** by default. A module costs a build file and longer paths for every feature and layer, and on a small project review already keeps the boundary. Split along the same tree into **modules** when something requires it:

- **A target**: the server is JVM only, and the client multiplatform; the wire contract compiles to every client target.
- **A second deployable** assembling the same features.
- **A team**, whose boundaries the build should enforce rather than review.

An architecture test (Konsist, ArchUnit) checks the import rules above without splitting modules. How many deployables a server has, and who owns which database schema, are project decisions recorded in an ADR.

## Naming Rules

### Naming modules

Names of modules are **always lower case** (`app`). Multi-word names are discouraged, but when needed use **snake case** (`selection-store`). Do not prefix module names with a company name (e.g. `cz-app`).

### Naming packages

Names of packages are **always lower case** and do NOT use underscores (`com.example.network`). Multi-word names are discouraged; if needed, simply concatenate them (`com.example.mypackage`).

### Naming test methods

In tests (and only in tests), it's acceptable to use method names with spaces enclosed in backticks. Underscores in method names are also allowed in test code.

```kotlin
class MyTestCase {
    @Test fun `ensure everything works`() { /* ... */ }

    @Test fun ensureEverythingWorks_onAndroid() { /* ... */ }
}
```

A backtick name must not contain a comma: Kotlin/Native rejects it (`Name contains illegal characters: ","`), while `jvmTest` compiles and passes without a word. Only a full build that compiles the Kotlin/Native test targets (iOS, macOS, …) catches it, minutes later or on CI. Reformulate rather than punctuate: `reads the clock once so it is never redeemed before it was created`. Apostrophes are fine.

### Name call arguments

When passing arguments that are not named in a property (`null`, a magic string, or a magic number), add argument names. It adds context and makes review easier.

```kotlin
val draft = DraftItem(
    existingDraftMetadata.id,
    null,                // bad
    "",                  // bad
    dateOfCreation,
)
```

```kotlin
val draft = DraftItem(
    existingDraftMetadata.id,
    imageUrl = null,     // good
    title = "",          // good
    dateOfCreation,
)
```

### Choosing good names

**Names should be meaningful and concise.** Make it clear what the entity's purpose is; avoid generic words (`Manager`, `Wrapper`, etc.).

- A class name is usually a noun or noun phrase explaining what the class _is_: `List`, `PersonReader`.
- A method name is usually a verb or verb phrase saying what the method _does_: `close`, `readPersons`. The name should suggest whether the method mutates the object or returns a new one (`sort` sorts in place; `sorted` returns a sorted copy).

When using an acronym in a declaration name, capitalize it if it consists of two letters (`IOStream`); capitalize only the first letter if it is longer (`XmlFormatter`, `HttpInputStream`).

### Naming in-memory repositories

Name in-memory repository implementations after their **strategy**, not after their role as a test double, never `FakeXxxRepository` or `MockXxxRepository`.

| Prefix   | Strategy                                 | Example                 |
| -------- | ---------------------------------------- | ----------------------- |
| `Ram`    | Mutable in-memory store; writes are kept | `RamUserListRepository` |
| `Sample` | Fixed sample data; effectively read-only | `SampleSpellRepository` |

`Ram` keeps only its first letter capitalized, per the acronym rule above.

These implementations belong to the feature's domain, in its `inmemory` package (`feature/<feature>/domain/inmemory/`), and to the **main source set**, not to a test source set: Compose previews depend on them too. They depend on nothing but the domain, so the presentation layer reaches them without importing the data layer. ViewModel tests reuse these implementations rather than declaring a test double of their own. The package is named after the strategy too: `inmemory` covers both prefixes, where `sample` would misfile a `Ram` store.

## Formatting

Formatting is **100% delegated to ktlint**. If the CI pipeline passes, the formatting is correct, no debates. Use the shared configuration in [`configs/.editorconfig`](https://github.com/cyrillrx/coding-conventions/blob/main/configs/.editorconfig); copy or symlink it into the project rather than configuring the IDE by hand.

That configuration enforces the layout (indentation, the 120-column limit, whitespace, wrapping, braces, blank lines and trailing commas), so none of it is restated here: ktlint's report is the reference. The rules below are the ones it does not check.

### Function and expression body formatting

Prefer an expression body for functions whose body is a single expression:

```kotlin
fun foo(): Int { return 1 }  // bad
fun foo() = 1                // good
```

### Control-flow formatting

Prefer affirmative conditions to negative ones:

```kotlin
if (statement) {   // good
    doIfTrue()
} else {
    doIfFalse()
}
```

Add a blank line after a conditional or a block that is followed by more statements.

## Code Idioms

### Kotlin idioms

- Favor immutability: use `val` over `var` and immutable collections (`List`, `Set`, `Map`) by default.
- Use Kotlin Coroutines and Flows for asynchronous programming.
- Use `require()`, `check()`, and `error()` for preconditions and state validation.
- Avoid nullable types where possible. Use sealed classes/interfaces for exhaustive states (`Loading`, `Success`, `Error`).
- Prefer method references (`::`) over explicit lambdas when signatures match: `router::openDetail` rather than `{ router.openDetail(it) }`.

### Early return

Prefer early-return syntax over deeply nested `if`/`else` blocks. It reduces nesting, keeps related branches close, reads linearly, and often spares the reader from scanning the whole method.

```kotlin
// Good
fun doSomething(someCondition: Boolean, name: String?, intValue: Int): String {

    if (!someCondition) {
        return "BAD_CONDITION"
    }

    if (name.isNullOrBlank()) {
        return "BAD_NAME"
    }

    if (intValue == 0) {
        return "BAD_VALUE"
    }

    // Do something

    return "SUCCESS"
}
```

Leave a blank line after a return statement to improve readability.

## Testing

### Rules

- Every bug fix must be accompanied by a regression test that fails before the fix and passes after.

### Domain tests

- Use `kotlin.test` (`kotlin.test.Test`, `kotlin.test.assertEquals`, …): no JUnit dependency needed for pure-function tests.
- One test file per function or class under test (e.g. `isValidWalkSpeed` → `IsValidWalkSpeedTest.kt`).
- Method names are backtick strings describing the expected behaviour in plain English.
- No setup, test doubles, or coroutines needed for pure functions: just call and assert.

```kotlin
class IsValidWalkSpeedTest {

    @Test
    fun `returns false for values below 25`() {
        assertFalse(isValidWalkSpeed(0))
        assertFalse(isValidWalkSpeed(24))
    }

    @Test
    fun `returns true for valid speeds`() {
        assertTrue(isValidWalkSpeed(25))
        assertTrue(isValidWalkSpeed(30))
    }
}
```

## Multiplatform

Applies to Kotlin Multiplatform projects only.

- **Targets**: Kotlin Multiplatform (KMP) targeting Android, iOS, and Desktop (JVM).
- **Shared module**: every feature and every `core` package live in the multiplatform module; the platform modules hold only their entry points.
- **Local Database**: SQLDelight (when persistence is needed).
- **Public API**: A public declaration of a shared module gets a KDoc when it has a contract its signature does not carry: a precondition, a thrown exception, the meaning of `null`, a unit, an invariant. A KDoc that only restates the name is a redundant comment (`coding-conventions.md` §4) and is left out.

## CI & Policies

Refer to [`git-and-collaboration.md`](https://github.com/cyrillrx/coding-conventions/blob/main/collaboration/git-and-collaboration.md) for general CI policies (warnings as errors, PR requirements, security scans).

Kotlin-specific CI requirements:
- PRs must pass `ktlintCheck`.
- On a Kotlin Multiplatform project, the project must build successfully for all targets (Android, iOS, Desktop).
