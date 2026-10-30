# Compose Testing Conventions

This document details how the ViewModels and user journeys of a Compose Multiplatform app are tested. The code under test follows the [Compose conventions](compose-conventions.md) and the [Compose ViewModel conventions](compose-viewmodel-conventions.md).

## Table of Contents

- [Rules](#rules)
- [ViewModel tests](#viewmodel-tests)
- [End-to-end tests](#end-to-end-tests)
- [What does NOT need tests](#what-does-not-need-tests)
- [CI & Policies](#ci--policies)

## Rules

- Every ViewModel must have a test file in the common test source set.
- Every new public method on an existing ViewModel must be covered by at least one test.
- Critical user journeys **should** be covered by an end-to-end flow: a strong recommendation, not a hard rule, since E2E runs locally rather than in CI (see [End-to-end tests](#end-to-end-tests)).

## ViewModel tests

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

## End-to-end tests

Critical user journeys are typically covered by end-to-end UI tests written with **Maestro**. E2E flows complement (never replace) ViewModel and domain unit tests: logic stays covered by unit tests, E2E only proves the journey holds together end to end.

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

# Fill and confirm the dialog: its nodes are addressed by id, not by label
- tapOn:
    id: "input_collection_name"
- inputText: "My Test Collection"
- tapOn:
    id: "button_confirm_create"

# Verify the collection appears in the list
- assertVisible:
    text: "My Test Collection"
```

**Targeting nodes**: matching a visible label by text is fine for navigation, but any node a flow addresses by identity (text fields, list containers, icon-only buttons) must expose a **stable id**: localized text changes with the copy and with the locale.

A Compose `testTag` reaches Maestro differently on each platform:

- **Android**: Maestro reads the accessibility tree, where a `testTag` only surfaces as a resource id once `testTagsAsResourceId` is enabled on an ancestor. That property is Android-only, so it cannot be set from `commonMain`, where screens and dialogs live.
- **iOS**: Compose Multiplatform maps a `testTag` to the node's `accessibilityIdentifier`, which Maestro reads as `id`. Nothing to enable: recent Compose Multiplatform resolves the accessibility tree on demand, so the earlier `accessibilitySyncOptions` opt-in is no longer required.

Wrap that difference in a single `expect` modifier instead of scattering platform code across screens:

```kotlin
// commonMain
expect fun Modifier.exposeTestTags(): Modifier

// androidMain
@OptIn(ExperimentalComposeUiApi::class) // needed while testTagsAsResourceId is @ExperimentalComposeUiApi
actual fun Modifier.exposeTestTags(): Modifier = semantics { testTagsAsResourceId = true }

// iosMain: testTag already maps to accessibilityIdentifier
actual fun Modifier.exposeTestTags(): Modifier = this

// jvmMain (Desktop): no E2E coverage
actual fun Modifier.exposeTestTags(): Modifier = this
```

`commonMain` holds the single `expect`; each target source set needs its own `actual` (or one shared intermediate source set). Maestro then targets the node with `id: "<testTag>"`.

Apply `exposeTestTags()` on every screen root **and again inside every dialog**: on Android the flag applies to a semantics **subtree**, and an `AlertDialog` renders in a separate window, so the flag set on the screen root never reaches the dialog content. A `testTag` set inside a dialog whose content does not call `exposeTestTags()` stays invisible to Maestro.

How a project names and centralizes the tags themselves is up to the project.

**Running the flows**: Maestro drives the installed app on a device or simulator, so flows are **not** part of the PR gate; run them locally before merging a change that touches a critical journey.

One set of flows covers both mobile platforms: on a full-Compose app the composable tree is identical, so a flow validates the journey once, and re-running it on the other platform validates the **platform layer** underneath (id resolution, system back, dialog windowing, `actual` implementations). **Android is the reference platform**: run the flows there for any change to a critical journey. Re-run them on iOS when the change touches platform-specific code (`actual` implementations, native interop, system navigation), or before a release.

Install the app first (substitute the project's own module, project, scheme and product names):

```bash
# Android: needs a connected device or a running emulator
./gradlew :<android-app-module>:installDebug

# iOS: needs a booted simulator
xcodebuild -project <ios-app-dir>/<project>.xcodeproj \
    -scheme <ios-scheme> \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=<device>' \
    -derivedDataPath build \
    build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/<product>.app
```

Then run the flows; the command is the same on both platforms:

```bash
maestro test .maestro/flows/
```

Maestro covers the Android and iOS apps only; the Desktop (JVM) target has no E2E coverage.

## What does NOT need tests

- Pure layout composables: covered by Compose previews.
- Trivial router/delegation classes: covered indirectly by ViewModel tests.

## CI & Policies

Maestro E2E flows are **not** a PR gate: they need a device or simulator; run them locally (see [End-to-end tests](#end-to-end-tests)).
