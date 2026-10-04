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

Code follows a **Clean Architecture** and **Layered** approach.

- **Domain**: Pure Kotlin. Contains entities and use cases. Independent of any framework.
- **Data**: Repositories abstract the data sources. Return Kotlin `Flow` for reactive data streams and `suspend` functions for one-shot operations.

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

Name in-memory repository implementations after their **strategy**, not after their role as a test double — never `FakeXxxRepository` or `MockXxxRepository`.

| Prefix   | Strategy                                 | Example                 |
| -------- | ---------------------------------------- | ----------------------- |
| `Ram`    | Mutable in-memory store; writes are kept | `RamUserListRepository` |
| `Sample` | Fixed sample data; effectively read-only | `SampleSpellRepository` |

`Ram` keeps only its first letter capitalized, per the acronym rule above.

These implementations belong to the **main source set** of the data layer (e.g. `shared/core/src/commonMain/.../<feature>/data/`), not to a test source set: Compose previews depend on them too. ViewModel tests reuse these implementations rather than declaring a test double of their own.

## Formatting

Formatting is **100% delegated to ktlint**. If the CI pipeline passes, the formatting is correct — no debates. Use the shared configuration in [`configs/kotlin/.editorconfig`](https://github.com/cyrillrx/coding-conventions/blob/main/configs/kotlin/.editorconfig); copy or symlink it into the project rather than configuring the IDE by hand.

The rules below describe what that configuration enforces, for reference.

### Indentation

Use 4 spaces for indentation. Do not use tabs.

### Line length

Keep lines to fewer than `120` characters unless there is a good reason not to.

### Horizontal whitespace

- Put spaces around binary operators (`a + b`). Exception: no spaces around the range operator (`0..i`).
- No spaces around unary operators (`a++`).
- Put a space between control-flow keywords (`if`, `when`, `for`, `while`) and the opening parenthesis.
- No space before the opening parenthesis in a primary constructor, method declaration, or method call.
- Never put a space after `(`, `[`, or before `]`, `)`.
- Never put a space around `.` or `?.`: `foo.bar().filter { it > 2 }`, `foo?.bar()`.
- Put a space after `//`.
- No spaces around angle brackets for type parameters (`Map<K, V>`), around `::` (`Foo::class`), or before `?` on a nullable type (`String?`).
- Avoid horizontal alignment of any kind: renaming an identifier should not force reformatting of surrounding lines.

### Function and expression body formatting

Prefer an expression body for functions whose body is a single expression:

```kotlin
fun foo(): Int { return 1 }  // bad
fun foo() = 1                // good
```

If the expression body doesn't fit on the declaration line, put `=` on the first line and indent the body by 4 spaces:

```kotlin
fun f(x: String) =
    x.length
```

### Control-flow formatting

If an `if`/`when` condition is multiline, use curly braces and put the closing parenthesis with the opening brace on a separate line:

```kotlin
if (!component.isSyncing &&
    !hasAnyKotlinRuntimeInScope(module)
) {
    return createKotlinNotConfiguredPanel(module)
}
```

Prefer affirmative conditions to negative ones:

```kotlin
if (statement) {   // good
    doIfTrue()
} else {
    doIfFalse()
}
```

Put `else`, `catch`, `finally`, and the `while` of a do/while on the same line as the preceding closing brace.

### Chained call wrapping

When wrapping chained calls, put `.` or `?.` on the next line with a single indent:

```kotlin
val anchor = owner
    ?.firstChild
    .siblings(forward = true)
    .dropWhile { it is PsiComment || it is PsiWhiteSpace }
```

### New lines

Add a new line after conditionals and blocks. Include exactly one blank line between methods — no more.

### Trailing commas

Add a trailing comma after function, constructor, and lambda parameters when there is more than one parameter. It simplifies diffs when adding parameters.

```kotlin
// good
class YesCommas(
    val foo: Int,
    val bar: Int,
)

// good — single param, no comma
class OneLineNoComma(val foo: Int)
```

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

- Use `kotlin.test` (`kotlin.test.Test`, `kotlin.test.assertEquals`, …) — no JUnit dependency needed for pure-function tests.
- One test file per function or class under test (e.g. `isValidWalkSpeed` → `IsValidWalkSpeedTest.kt`).
- Method names are backtick strings describing the expected behaviour in plain English.
- No setup, test doubles, or coroutines needed for pure functions — just call and assert.

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
- **Shared modules**: Pure Kotlin domain/data code lives in shared modules.
- **Local Database**: SQLDelight (when persistence is needed).
- **Public API**: Use KDoc for public APIs in shared modules to clearly define their contracts.

## CI & Policies

Refer to [`git-and-collaboration.md`](https://github.com/cyrillrx/coding-conventions/blob/main/collaboration/git-and-collaboration.md) for general CI policies (warnings as errors, PR requirements, security scans).

Kotlin-specific CI requirements:
- PRs must pass `ktlintCheck`.
- On a Kotlin Multiplatform project, the project must build successfully for all targets (Android, iOS, Desktop).
