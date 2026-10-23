# Compose ViewModel Conventions

This document details how the ViewModels of a Compose Multiplatform app are named, shaped and refreshed. They sit behind the composables described in the [Compose conventions](compose-conventions.md#presentation-layer-mvvm--udf), and are tested per the [Compose testing conventions](compose-testing-conventions.md).

## Table of Contents

- [ViewModel Method Naming](#viewmodel-method-naming)
- [ViewModel State Shape](#viewmodel-state-shape)
- [ViewModel Flow Declarations](#viewmodel-flow-declarations)
- [One-shot events via SharedFlow](#one-shot-events-via-sharedflow)
- [Lifecycle-aware Refresh](#lifecycle-aware-refresh)

## ViewModel Method Naming

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

## ViewModel State Shape

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

## ViewModel Flow Declarations

Use Kotlin 2.0 explicit backing fields to expose flows with a narrower public type, avoiding a separate private backing property:

```kotlin
// ✅ Explicit backing field — single declaration, narrowed public type
val state: StateFlow<XxxState>
    field = MutableStateFlow<XxxState>(XxxState.Loading)

val coercedValueEvent: SharedFlow<Int>
    field = MutableSharedFlow<Int>(extraBufferCapacity = 1)
```

Within the class body the property resolves to its backing field's concrete type (`MutableStateFlow`, `MutableSharedFlow`), so mutation methods are available directly.

## One-shot events via SharedFlow

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
