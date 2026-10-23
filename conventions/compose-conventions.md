# Compose Conventions

This document details the architectural patterns and style rules for the composables of Kotlin Multiplatform apps built with Compose Multiplatform (CMP). It also covers Android-specific Compose style. Its ViewModels follow the [Compose ViewModel conventions](compose-viewmodel-conventions.md), and its tests the [Compose testing conventions](compose-testing-conventions.md).

It builds on the [Kotlin conventions](kotlin-conventions.md), which apply to every module of the app, and the general [Clean Code principles](coding-conventions.md).

## Table of Contents

- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Naming Rules](#naming-rules)
- [Compose Guidelines](#compose-guidelines)
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
- **Apostrophes in Compose resources**: Write them plain (`J'ai un code`), never escaped: unlike Android resources, a `strings.xml` under `composeResources/` keeps the backslash of `\'` and shows it on screen. Nothing warns — the build stays green, and only the rendered screen, or the base64 in `build/generated/compose/resourceGenerator/preparedResources/**/values*/strings.*.cvr`, shows it.

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

## CI & Policies

Refer to the [Kotlin conventions](kotlin-conventions.md#ci--policies) for the ktlint and build requirements.
