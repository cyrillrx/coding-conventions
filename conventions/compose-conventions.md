# Compose Conventions

This document details the architectural patterns, style rules, and testing guidelines for the UI layer of Kotlin Multiplatform apps built with Compose Multiplatform (CMP). It also covers Android-specific Compose style.

It builds on the [Kotlin conventions](kotlin-conventions.md), which apply to every module of the app, and the general [Clean Code principles](coding-conventions.md).

## Table of Contents

- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Naming Rules](#naming-rules)
- [Compose Guidelines](#compose-guidelines)
- [Lifecycle-aware Refresh](#lifecycle-aware-refresh)
- [Testing](#testing)
- [CI & Policies](#ci--policies)

## Tech Stack

- **UI Framework**: Compose Multiplatform — no XML layouts, no View-system APIs.

## Architecture

The presentation layer (Compose + ViewModels) lives in the app module, on top of the domain and data layers described in the [Kotlin conventions](kotlin-conventions.md#architecture).

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

## Naming Rules

### Naming image resources

- **Icons** (mono-color, defined in the design system): prefixed by `ic_` and suffixed by their size in dp. `ic_activity_24` is the `activity` icon at 24×24. Mono-color icons can be tinted at use.
- **Multicolor images** (design-system vectors): prefixed by `img_` and suffixed by their size in dp. `img_package_72` is the `package` image at 72×72. These cannot be tinted at use; define colors via the design-system theme rather than hardcoding, and import both light and dark variants.

## Compose Guidelines

- **Naming**: Composable functions returning `Unit` must be `PascalCase` (e.g. `CreateCampaignScreen`). Composables returning a value are `camelCase`.
- **Modifiers**: Every Composable should accept a `modifier: Modifier = Modifier` as the first optional parameter.
- **State Hoisting**: Hoist state to the lowest common parent. Composables should be as stateless as possible.
- **Previews**: Write `@Preview` functions for all UI components. Use `androidx.compose.ui.tooling.preview.Preview` from the Multiplatform `ui-tooling-preview` module.
- **Resources**: Use the generated KMP resources (`Res.string.xxx`, `Res.drawable.xxx`).
- **Apostrophes in Compose resources**: Write them plain (`J'ai un code`), never escaped: unlike Android resources, a `strings.xml` under `composeResources/` keeps the backslash of `\'` and shows it on screen. Nothing warns — the build stays green, and only the rendered screen, or the base64 in `build/generated/compose/resourceGenerator/preparedResources/**/values-*/strings.*.cvr`, shows it.

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
- Critical user journeys **should** be covered by an end-to-end flow — a strong recommendation, not a hard rule, since E2E runs locally rather than in CI (see [End-to-end tests](#end-to-end-tests)).

### ViewModel tests

- **Coroutines**: `StandardTestDispatcher` + `runTest`.
- **Dependencies**: inject repositories through the ViewModel constructor.
- **In-memory repositories**: reuse the `Ram`/`Sample` implementations described in [Naming in-memory repositories](kotlin-conventions.md#naming-in-memory-repositories) rather than declaring a new test double for each test.

Required cases:

| Case                                    | Description                                              |
| --------------------------------------- | -------------------------------------------------------- |
| Initial `Loading` state                 | Before coroutines have run                               |
| `Error` state                           | When the repository throws                               |
| Happy path `WithData`                   | Data loaded and displayed correctly                      |
| `silentRefresh` reflects repo changes   | After mutating the repo, `silentRefresh()` updates state |
| `silentRefresh` does not show `Loading` | State does not regress to `Loading` during refresh       |
| `silentRefresh` no-op when `Loading`    | Early call has no effect                                 |

For ViewModels with mutations (delete, rename, add): test optimistic mutation, undo, commit, and repository persistence.

### End-to-end tests

Critical user journeys are typically covered by end-to-end UI tests written with **Maestro**. E2E flows complement — never replace — ViewModel and domain unit tests: logic stays covered by unit tests, E2E only proves the journey holds together end to end.

**Flows** live in a `.maestro/flows/` directory, one file per journey, named after the journey in kebab-case (`create-collection.yaml`). Start from a clean state, comment each navigation step, and finish on an explicit assertion of the journey's outcome.

```yaml
appId: com.example.app
---
- launchApp:
    clearState: true

# Navigate to the collections screen
- tapOn:
    text: "Collections"

# Open the create-collection dialog
- tapOn:
    text: "Create"

# Fill and confirm the dialog — its nodes are addressed by id, not by label
- tapOn:
    id: "input_collection_name"
- inputText: "My Test Collection"
- tapOn:
    id: "button_confirm_create"

# Verify the collection appears in the list
- assertVisible:
    text: "My Test Collection"
```

**Targeting nodes** — matching a visible label by text is fine for navigation, but any node a flow addresses by identity (text fields, list containers, icon-only buttons) must expose a **stable id**: localized text changes with the copy and with the locale.

A Compose `testTag` reaches Maestro differently on each platform:

- **Android** — Maestro reads the accessibility tree, where a `testTag` only surfaces as a resource id once `testTagsAsResourceId` is enabled on an ancestor. That property is Android-only, so it cannot be set from `commonMain`, where screens and dialogs live.
- **iOS** — Compose Multiplatform maps a `testTag` to the node's `accessibilityIdentifier`, which Maestro reads as `id`. Nothing to enable: recent Compose Multiplatform resolves the accessibility tree on demand, so the earlier `accessibilitySyncOptions` opt-in is no longer required.

Wrap that difference in a single `expect` modifier instead of scattering platform code across screens:

```kotlin
// commonMain
expect fun Modifier.exposeTestTags(): Modifier

// androidMain
@OptIn(ExperimentalComposeUiApi::class) // needed while testTagsAsResourceId is @ExperimentalComposeUiApi
actual fun Modifier.exposeTestTags(): Modifier = semantics { testTagsAsResourceId = true }

// iosMain — testTag already maps to accessibilityIdentifier
actual fun Modifier.exposeTestTags(): Modifier = this

// jvmMain (Desktop) — no E2E coverage
actual fun Modifier.exposeTestTags(): Modifier = this
```

`commonMain` holds the single `expect`; each target source set needs its own `actual` (or one shared intermediate source set). Maestro then targets the node with `id: "<testTag>"`.

Apply `exposeTestTags()` on every screen root **and again inside every dialog**: on Android the flag applies to a semantics **subtree**, and an `AlertDialog` renders in a separate window, so the flag set on the screen root never reaches the dialog content. A `testTag` set inside a dialog whose content does not call `exposeTestTags()` stays invisible to Maestro.

How a project names and centralizes the tags themselves is up to the project.

**Running the flows** — Maestro drives the installed app on a device or simulator, so flows are **not** part of the PR gate; run them locally before merging a change that touches a critical journey.

One set of flows covers both mobile platforms: on a full-Compose app the composable tree is identical, so a flow validates the journey once, and re-running it on the other platform validates the **platform layer** underneath (id resolution, system back, dialog windowing, `actual` implementations). **Android is the reference platform** — run the flows there for any change to a critical journey. Re-run them on iOS when the change touches platform-specific code (`actual` implementations, native interop, system navigation), or before a release.

Install the app first (substitute the project's own module, project, scheme and product names):

```bash
# Android — needs a connected device or a running emulator
./gradlew :<android-app-module>:installDebug

# iOS — needs a booted simulator
xcodebuild -project <ios-app-dir>/<project>.xcodeproj \
    -scheme <ios-scheme> \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=<device>' \
    -derivedDataPath build \
    build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/<product>.app
```

Then run the flows — the command is the same on both platforms:

```bash
maestro test .maestro/flows/
```

Maestro covers the Android and iOS apps only; the Desktop (JVM) target has no E2E coverage.

### What does NOT need tests

- Pure layout composables — covered by Compose previews.
- Trivial router/delegation classes — covered indirectly by ViewModel tests.

## CI & Policies

Refer to the [Kotlin conventions](kotlin-conventions.md#ci--policies) for the ktlint and build requirements.

Maestro E2E flows are **not** a PR gate — they need a device or simulator; run them locally (see [End-to-end tests](#end-to-end-tests)).
