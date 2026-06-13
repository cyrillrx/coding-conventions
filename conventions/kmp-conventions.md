# Kotlin Multiplatform & Compose Conventions

This document details the architectural patterns, style rules, and testing guidelines for Kotlin Multiplatform (KMP) and Compose Multiplatform (CMP) code. It also covers Android-specific Kotlin/Compose style.

It builds on [Kotlin's coding conventions](https://kotlinlang.org/docs/reference/coding-conventions.html) and the general [Clean Code principles](coding-conventions.md).

## Table of Contents

- [Tech Stack & Dependency Management](#tech-stack--dependency-management)
- [Source Code Organization](#source-code-organization)
- [Architecture](#architecture)
- [Naming Rules](#naming-rules)
- [Formatting](#formatting)
- [Code Idioms](#code-idioms)
- [Compose Guidelines](#compose-guidelines)
- [Lifecycle-aware Refresh](#lifecycle-aware-refresh)
- [Testing](#testing)
- [CI & Policies](#ci--policies)

## Tech Stack & Dependency Management

- **Language**: Kotlin (latest stable version).
- **Multiplatform**: Kotlin Multiplatform (KMP) targeting Android, iOS, and Desktop (JVM).
- **UI Framework**: Compose Multiplatform — no XML layouts, no View-system APIs.
- **Local Database**: SQLDelight (when persistence is needed).
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

The application follows a **Clean Architecture** and **Layered** approach adapted for Kotlin Multiplatform. Pure Kotlin domain/data code lives in shared modules; the presentation layer (Compose + ViewModels) lives in the app module.

### Presentation Layer (MVVM + UDF)

- **Use Model-View-ViewModel (MVVM)**.
- **Follow Unidirectional Data Flow (UDF)**:
    - State flows down: ViewModels expose a single `StateFlow<ViewState>`.
    - Events flow up: Composables pass user actions to the ViewModel via lambda callbacks (e.g. `onCreateCampaignClicked = viewModel::openCreateCampaign`).
- **Keep ViewModels platform-agnostic** using `lifecycle-viewmodel-compose` from JetBrains.
- **Do not pass ViewModels down the Composable tree**. Pass state and lambda callbacks instead.

### ViewModel Method Naming

ViewModel public methods must reflect **behavior** (what the app does), not the UI event that triggered them. Composable callback parameters keep the UI-event convention because they are generic lambda slots.

| Context                       | Convention                     | Examples                                               |
| ----------------------------- | ------------------------------ | ------------------------------------------------------ |
| Composable callback parameter | `onXxxClicked`, `onXxxChanged` | `onCreateCampaignClicked`, `onSearchQueryChanged`      |
| ViewModel public method       | Functional verb phrase         | `openCreateCampaign`, `filterByQuery`, `silentRefresh` |

```kotlin
// ✅ Correct — callback param name ≠ ViewModel method name
fun CampaignListScreen(viewModel: CampaignListViewModel, router: CampaignRouter) {
    CampaignListScreen(
        onSearchQueryChanged = viewModel::filterByQuery,
        onCampaignClicked = viewModel::openCampaignDetail,
        onCreateCampaignClicked = viewModel::openCreateCampaign,
    )
}
```

### ViewModel State Shape

Every ViewModel exposes a single `StateFlow<XxxState>`. The shape of `XxxState` depends on the screen type.

**List / read-only screens** — use a data class with a sealed `Body` field:

```kotlin
data class SpellListState(val body: Body = Body.Loading) {
    sealed interface Body {
        data object Loading : Body
        data object Empty : Body
        data class WithData(val spells: List<Spell>) : Body
        data class Error(val message: String) : Body
    }
}
```

**Edit / detail screens** — use a top-level sealed interface whose states model the data-fetch lifecycle:

```kotlin
sealed interface CharacterEditState {
    data object Loading : CharacterEditState
    data class NotFound(val id: String) : CharacterEditState
    data class Loaded(/* ... */) : CharacterEditState
}
```

- `Loading` — initial state, set synchronously before the repository call.
- `NotFound` — set when the repository returns `null`; carries the ID for error display.
- `Loaded` — the active, mutable state of the screen; the only state that accepts user interactions.

The screen's ViewModel-taking overload uses an exhaustive `when` on the sealed state; the stateless overload takes `XxxState.Loaded` directly.

### ViewModel Flow Declarations

Use Kotlin 2.0 explicit backing fields to expose flows with a narrower public type, avoiding a separate private backing property:

```kotlin
// ✅ Explicit backing field — single declaration, narrowed public type
val state: StateFlow<XxxState>
    field = MutableStateFlow<XxxState>(XxxState.Loading)

val coercedValueEvent: SharedFlow<Int>
    field = MutableSharedFlow<Int>(extraBufferCapacity = 1)
```

Within the class body the property resolves to its backing field's concrete type (`MutableStateFlow`, `MutableSharedFlow`), so mutation methods are available directly.

### One-shot events via SharedFlow

For events the UI must consume exactly once (snackbar notifications, navigation triggers), expose a `SharedFlow<T>` with `extraBufferCapacity = 1`. Collect it in the ViewModel-taking composable with `LaunchedEffect`:

```kotlin
// ViewModel
val coercedValueEvent: SharedFlow<Int>
    field = MutableSharedFlow<Int>(extraBufferCapacity = 1)

// Composable
val messageTemplate = stringResource(Res.string.info_value_coerced)
LaunchedEffect(viewModel) {
    viewModel.coercedValueEvent.collect { value ->
        snackbarHostState.showSnackbar(messageTemplate.format(value))
    }
}
```

Use `StateFlow` for state that must survive recomposition; use `SharedFlow` (`extraBufferCapacity = 1`, replay = 0) for fire-and-forget events such as navigation or snackbars.

### Navigation callbacks in primary composables

Do not inject the router into ViewModels. Because the ViewModel outlives configuration changes (rotation), an injected router reference can point to a stale back stack after recreation. **Always bind navigation callbacks directly to the fresh `router` parameter in the ViewModel-taking composable overload** — never to ViewModel methods that delegate to an injected router.

```kotlin
// ✅ Correct — navigation goes through the fresh router parameter
fun CharacterListScreen(viewModel: CharacterListViewModel, router: CharacterRouter) {
    CharacterListScreen(
        onCharacterClicked = router::openCharacterDetail,
        onNewCharacterClicked = router::openCreateCharacter,
        onNavigateUpClicked = router::navigateUp,
    )
}
```

When a ViewModel must navigate **after async work** (e.g. save before navigate), expose a `SharedFlow<NavigationEvent>` and collect it in a `LaunchedEffect(viewModel)` in the primary composable.

### Domain & Data Layers

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

### Naming constants

#### Arguments of Activities/Fragments

Activity (and Fragment) argument names should be **prefixed** by `ARG_`, e.g. `ARG_PRODUCT_TAG`:

```kotlin
companion object {
    private const val ARG_MIN_PHOTO_COUNT = "min_photo_count"
    private const val ARG_SELECTION_ID = "selection_id"
}
```

#### Keys of key/value pairs

Constants for keys must be **prefixed** by `KEY_` (this does not apply to Activity/Fragment arguments), e.g. `KEY_PRODUCT_TAG`. Group and prefix related keys together:

```kotlin
const val KEY_PRODUCT_TAG_MAGNET = "product_tag_magnet"
const val KEY_PRODUCT_TAG_DIBOND = "product_tag_dibond"

const val KEY_ACTION_ADD = "action_add"
const val KEY_ACTION_DELETE = "action_delete"
```

### Naming image resources

- **Icons** (mono-color, defined in the design system): prefixed by `ic_` and suffixed by their size in dp. `ic_activity_24` is the `activity` icon at 24×24. Mono-color icons can be tinted at use.
- **Multicolor images** (design-system vectors): prefixed by `img_` and suffixed by their size in dp. `img_package_72` is the `package` image at 72×72. These cannot be tinted at use; define colors via the design-system theme rather than hardcoding, and import both light and dark variants.

## Formatting

Formatting is **100% delegated to ktlint**. If the CI pipeline passes, the formatting is correct — no debates. Use the shared configuration in [`configs/kotlin/.editorconfig`](../configs/kotlin/.editorconfig); copy or symlink it into the project rather than configuring the IDE by hand.

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

## Compose Guidelines

- **Naming**: Composable functions returning `Unit` must be `PascalCase` (e.g. `CreateCampaignScreen`). Composables returning a value are `camelCase`.
- **Modifiers**: Every Composable should accept a `modifier: Modifier = Modifier` as the first optional parameter.
- **State Hoisting**: Hoist state to the lowest common parent. Composables should be as stateless as possible.
- **Previews**: Write `@Preview` functions for all UI components. Use `androidx.compose.ui.tooling.preview.Preview` from the Multiplatform `ui-tooling-preview` module.
- **Resources**: Use the generated KMP resources (`Res.string.xxx`, `Res.drawable.xxx`).

### List state

Use `LazyColumn` / `LazyRow` for lists. When the parent needs to control or observe scroll position, hoist a `LazyListState`; otherwise let the list own it internally — don't hoist unnecessarily.

```kotlin
val listState = rememberLazyListState()

LazyColumn(state = listState) {
    items(items) { item -> ItemRow(item) }
}

// Elsewhere: scroll to top on refresh
LaunchedEffect(refreshTrigger) {
    listState.animateScrollToItem(0)
}
```

### Visibility

Showing or hiding content is expressed with a plain `if`. There is no equivalent of `INVISIBLE` (occupying space while hidden) — use `Spacer` with a fixed size if a placeholder is needed. Prefer `AnimatedVisibility` when the appearance/disappearance benefits from a transition.

```kotlin
if (isCompanyInfoVisible) {
    CompanyInfoSection()
}

AnimatedVisibility(visible = isCompanyInfoVisible) {
    CompanyInfoSection()
}
```

### Content description

For decorative images and icons, use `null` rather than an empty string for `contentDescription`:

```kotlin
LoadableImage(url = url, contentDescription = null)  // good
LoadableImage(url = url, contentDescription = "")    // bad
```

## Lifecycle-aware Refresh

Screens that display mutable data (persisted in a repository) must refresh when the user returns to the screen via `LifecycleEventEffect(Lifecycle.Event.ON_RESUME)`. Use `silentRefresh()` — never the full load function — to avoid a flicker when data is already visible.

Every ViewModel with `ON_RESUME` refresh exposes two distinct operations:

| Method                     | Sets `Loading` | Purpose                                                                             |
| -------------------------- | -------------- | ----------------------------------------------------------------------------------- |
| `loadXxx()` (private)      | ✅ Yes         | Initial load from `init`, or after an explicit user action (search change, refresh) |
| `silentRefresh()` (public) | ❌ No          | Called by the screen on `ON_RESUME`; no-ops when state is already `Loading`         |

```kotlin
fun silentRefresh() {
    if (state.value.body is XxxState.Body.Loading) return

    viewModelScope.launch {
        try {
            fetchAndUpdate()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // Keep existing state on refresh failure
        }
    }
}
```

```kotlin
LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
    viewModel.silentRefresh()
}
```

Never call a load function from `ON_RESUME`: the `init` block already handles the initial load, so doing so causes a redundant double fetch and an unnecessary `Loading` flash on every back-navigation.

## Testing

### Rules

- Every ViewModel must have a test file in the common test source set.
- Every new public method on an existing ViewModel must be covered by at least one test.
- Every bug fix must be accompanied by a regression test that fails before the fix and passes after.

### ViewModel tests

Use `StandardTestDispatcher` + `runTest`. Inject repositories via the constructor; use in-memory fakes. Required cases:

| Case                                    | Description                                              |
| --------------------------------------- | -------------------------------------------------------- |
| Initial `Loading` state                 | Before coroutines have run                               |
| `Error` state                           | When the repository throws                               |
| Happy path `WithData`                   | Data loaded and displayed correctly                      |
| `silentRefresh` reflects repo changes   | After mutating the repo, `silentRefresh()` updates state |
| `silentRefresh` does not show `Loading` | State does not regress to `Loading` during refresh       |
| `silentRefresh` no-op when `Loading`    | Early call has no effect                                 |

For ViewModels with mutations (delete, rename, add): test optimistic mutation, undo, commit, and repository persistence.

### Domain tests

- Use `kotlin.test` (`kotlin.test.Test`, `kotlin.test.assertEquals`, …) — no JUnit dependency needed for pure-function tests.
- One test file per function or class under test (e.g. `isValidWalkSpeed` → `IsValidWalkSpeedTest.kt`).
- Method names are backtick strings describing the expected behaviour in plain English.
- No setup, fakes, or coroutines needed for pure functions — just call and assert.

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

### What does NOT need tests

- Pure layout composables — covered by Compose previews.
- Trivial router/delegation classes — covered indirectly by ViewModel tests.

## CI & Policies

Refer to [`git-and-collaboration.md`](../collaboration/git-and-collaboration.md) for general CI policies (warnings as errors, PR requirements, security scans).

KMP-specific CI requirements:
- PRs must pass `ktlintCheck` and the project must build successfully for all targets (Android, iOS, Desktop).
- Use KDoc for public APIs in shared modules to clearly define their contracts.
