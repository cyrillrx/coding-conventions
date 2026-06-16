---
name: kmp-style
description: This team's Kotlin Multiplatform / Compose conventions — MVVM + UDF architecture, state and event modeling, naming, formatting, testing. Use when editing .kt files, building Compose screens or ViewModels, or reviewing Kotlin style.
---

<!--
Generated from conventions/kmp-conventions.md and conventions/coding-conventions.md
in cyrillrx/coding-conventions. Do not edit manually — run /sync-plugins.
-->

# Kotlin Multiplatform & Compose conventions

Follow these rules when writing or reviewing Kotlin / Compose / KMP code. They build on general Clean Code principles (small functions, meaningful names, fail fast, favor immutability).

## Architecture — MVVM + UDF

- ViewModels expose a **single** `StateFlow<XxxState>`. State flows down; events flow up via lambda callbacks.
- **Do not pass ViewModels down the composable tree** — pass state and lambdas. Keep ViewModels platform-agnostic.
- **ViewModel method names reflect behavior** (`openCreateCampaign`, `filterByQuery`, `silentRefresh`), not the UI event. Composable callback parameters keep the UI-event convention (`onCreateCampaignClicked`, `onSearchQueryChanged`).
- **Domain** is pure Kotlin (entities, use cases). **Data** repositories return `Flow` for streams and `suspend` for one-shot operations.

## State & event modeling

- **List / read-only screens**: a data class with a sealed `Body` field (`Loading`, `Empty`, `WithData`, `Error`).
- **Edit / detail screens**: a top-level sealed interface modeling the fetch lifecycle (`Loading`, `NotFound`, `Loaded`). Only `Loaded` accepts user interaction; the stateless overload takes `XxxState.Loaded`.
- **Expose flows with Kotlin 2.0 explicit backing fields**, narrowing the public type:
  ```kotlin
  val state: StateFlow<XxxState>
      field = MutableStateFlow<XxxState>(XxxState.Loading)
  ```
- **One-shot events** (snackbars, navigation): `SharedFlow<T>` with `extraBufferCapacity = 1`, collected in a `LaunchedEffect(viewModel)`. Use `StateFlow` for state that survives recomposition.

## Navigation

- **Never inject the router into a ViewModel** — it outlives configuration changes and goes stale. Bind navigation callbacks to the fresh `router` parameter in the ViewModel-taking composable overload.
- To navigate **after async work**, emit a `SharedFlow<NavigationEvent>` and collect it in a `LaunchedEffect(viewModel)` in the primary composable.

## Lifecycle-aware refresh

Screens showing mutable persisted data refresh on `LifecycleEventEffect(Lifecycle.Event.ON_RESUME)` using a public `silentRefresh()` that **does not** set `Loading` (no-ops while already `Loading`). Never call the full load function from `ON_RESUME` — the `init` block already handles the initial load.

## Compose

- Composables returning `Unit` are `PascalCase`; those returning a value are `camelCase`.
- Every composable takes `modifier: Modifier = Modifier` as the first optional parameter.
- Hoist state to the lowest common parent; keep composables stateless. Hoist `LazyListState` only when the parent needs scroll control.
- Show/hide with a plain `if`; use `AnimatedVisibility` for transitions. There is no `INVISIBLE` — use a sized `Spacer` as a placeholder.
- Write `@Preview` functions for UI components. Use generated resources (`Res.string.xxx`, `Res.drawable.xxx`).
- Decorative images/icons use `contentDescription = null`, never `""`.

## Kotlin idioms

- `val` over `var`; immutable collections by default.
- `require()` / `check()` / `error()` for preconditions.
- Sealed classes/interfaces for exhaustive states; avoid nullable types where possible.
- Method references (`router::openDetail`) over explicit lambdas when signatures match.
- **Early return** over deep nesting; leave a blank line after a guard clause.

## Naming

- Packages lowercase, no underscores. Modules lowercase (snake_case if multi-word), no company prefix.
- `ARG_` prefix for Activity/Fragment argument keys; `KEY_` prefix for other key constants (grouped by prefix).
- Image resources: `ic_<name>_<size>` for mono-color icons, `img_<name>_<size>` for multicolor images.
- Test methods may use backtick names with spaces.

## Formatting

Formatting is **100% delegated to ktlint** via the shared `configs/kotlin/.editorconfig` (4-space indent, 120-col lines, trailing commas on multi-param declarations). Don't hand-tune the IDE.

## Testing

- Every ViewModel has a test (common test source set); every new public ViewModel method and every bug fix gets a test.
- ViewModel tests use `StandardTestDispatcher` + `runTest` with in-memory fakes; cover initial `Loading`, `Error`, happy-path `WithData`, and the `silentRefresh` cases.
- Pure functions: `kotlin.test`, one test file per function, backtick method names, no setup/fakes/coroutines.
- No tests for pure layout composables (previews) or trivial delegation classes.
