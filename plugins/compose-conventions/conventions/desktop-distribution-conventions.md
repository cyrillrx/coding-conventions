# Desktop Distribution Conventions

This document details how a Compose Multiplatform Desktop (JVM) application is shipped to users: how it guards its data at startup, how it is packaged, versioned, released, signed and updated. It covers macOS and Windows; Linux is optional and follows the same rules where it applies.

It builds on the [Kotlin conventions](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/kotlin-conventions.md) and the [Compose conventions](https://github.com/cyrillrx/coding-conventions/blob/main/conventions/compose-conventions.md), which cover the code itself.

## Table of Contents

- [Application Data Directory](#application-data-directory)
- [Single Instance](#single-instance)
- [Packaging](#packaging)
- [Versioning](#versioning)
- [Release Workflow](#release-workflow)
- [Signing](#signing)
- [Updates](#updates)

## Application Data Directory

Everything the application persists — local database, preferences, caches it cannot rebuild cheaply, the single-instance lock — lives in one per-user application data directory, at the location each OS reserves for it:

| OS      | Directory                                                      |
|---------|----------------------------------------------------------------|
| macOS   | `~/Library/Application Support/<App>`                          |
| Windows | `%APPDATA%\<App>`, falling back to the user's home directory   |
| Linux   | `$XDG_DATA_HOME/<App>`, falling back to `~/.local/share/<App>` |

- Never use the system temp directory. The OS purges it on its own schedule, so the user's data disappears without any action on their part.
- Resolve the directory once, in a single function, and pass the resulting path to whatever needs it. Two components computing it separately end up disagreeing on one OS.

```kotlin
fun applicationDataDirectory(appName: String): Path {
    val home = Path(System.getProperty("user.home"))
    val os = System.getProperty("os.name").lowercase()
    return when {
        os.startsWith("mac") -> home / "Library" / "Application Support" / appName
        os.startsWith("windows") -> (System.getenv("APPDATA")?.let(::Path) ?: home) / appName
        else -> {
            val xdgDataHome = System.getenv("XDG_DATA_HOME")?.takeIf(String::isNotEmpty)?.let(::Path)
            (xdgDataHome ?: home / ".local" / "share") / appName
        }
    }
}
```

## Single Instance

Two instances of the application sharing one data directory corrupt each other's state, and nothing reports it: one instance rewriting a whole-file store erases the keys the other just saved, and two processes writing one local database interleave their changes. A desktop application therefore runs as a single instance, on every OS.

### Taking the lock

- The first instance takes an OS file lock — `FileChannel.tryLock()` — on an `instance.lock` file in the application data directory, **before anything else touches that directory**. Opening the database or reading preferences first defeats the lock.
- Create the directory if it is missing, right before taking the lock: on a fresh install nothing has created it yet, and opening the lock file in a missing directory fails. Creating the directory is the only thing that comes before the lock.
- Keep a reference to the returned lock for the whole lifetime of the process, in a top-level `val` for instance. The lock lasts as long as its channel stays open, and the garbage collector can close a channel nothing references any more.
- The OS releases the lock when the process dies, crash included. That is why the lock is a file lock and not a PID file: a PID file left behind by a crash blocks the next launch, or forces guessing whether its process is still alive.
- `tryLock()` returns `null` when another process holds the lock, and throws `OverlappingFileLockException` when the same JVM already holds it. Treat both as "held".

```kotlin
fun tryLockInstance(dataDirectory: Path): FileLock? {
    Files.createDirectories(dataDirectory)
    val channel = FileChannel.open(dataDirectory / "instance.lock", CREATE, WRITE)
    val lock = try {
        channel.tryLock()
    } catch (e: OverlappingFileLockException) {
        null
    }
    if (lock == null) channel.close()
    return lock
}
```

### Activating the running instance

A user who launches the application again expects the window they already have, not a silent no-op. The first instance therefore also listens for activation requests:

- The first instance listens on a Unix domain socket (`UnixDomainSocketAddress`, JDK 16 and later; supported on Windows 10 and later) in the application data directory. It deletes a leftover socket file before binding: that is safe, since only the lock holder reaches this point.
- A second instance connects to the socket, sends an activation request, and exits.
- On a request, the first instance brings its window to the front: un-minimize it, then `toFront()` and `requestFocus()`. The request arrives on the socket thread, so hand it over to the UI thread first. On Windows, focus-stealing prevention may flash the taskbar button instead of raising the window; that is the OS's rule, not a bug to work around.
- **Never run a degraded second instance** — one without sync, or read-only — silently. If the socket is unreachable (the first instance is still starting, or hung), the second instance exits anyway: a failed request is reported to the caller, never thrown at it.
- One failed request never stops the listener. A client that drops its connection must not end the listening thread, or every later launch sends its request to nobody and exits.

```kotlin
private const val ACTIVATE: Byte = 1

fun listenForActivation(dataDirectory: Path, onActivationRequested: () -> Unit) {
    val address = UnixDomainSocketAddress.of(dataDirectory / "instance.sock")
    Files.deleteIfExists(address.path)
    val server = ServerSocketChannel.open(StandardProtocolFamily.UNIX).bind(address)
    thread(isDaemon = true, name = "instance-activation") {
        while (true) {
            try {
                server.accept().use { client ->
                    val request = ByteBuffer.allocate(1)
                    if (client.read(request) > 0 && request.get(0) == ACTIVATE) onActivationRequested()
                }
            } catch (e: Exception) {
                // A dropped client or a failed activation only loses its own request: keep serving the next ones.
            }
        }
    }
}

/** Returns whether the running instance received the request. The caller exits either way. */
fun requestActivation(dataDirectory: Path): Boolean =
    try {
        SocketChannel.open(UnixDomainSocketAddress.of(dataDirectory / "instance.sock")).use { channel ->
            channel.write(ByteBuffer.wrap(byteArrayOf(ACTIVATE)))
        }
        true
    } catch (e: IOException) {
        false
    }
```

### Why on every OS

On macOS, a `.app` launched from the Finder or the Dock is already single-instance: LaunchServices reactivates the running copy. But `open -n`, a launch from a terminal, or the development `run` task each start a second process. The lock applies on every OS, macOS included.

### Where the logic lives

Keep the lock and the socket in a product-agnostic JVM module, not in the composable entry point. There they are testable with `jvmTest` — two locks on one temporary directory, an activation round trip — and the entry point only wires the outcome to the window.

## Packaging

Installers are built by the Compose Gradle plugin's `nativeDistributions` block, which drives `jpackage`. Some of its settings are optional to the plugin but required for a release:

| Setting                           | Why |
|-----------------------------------|---|
| `packageName`                     | The application name the user sees in the menu, the Dock and the installer. Not a Java package name |
| `macOS { bundleID }`              | The reverse-DNS identifier macOS uses to recognise the application across versions |
| `windows { upgradeUuid }`         | Generated once and never changed. Without it, or if it changes, each MSI installs next to the previous one instead of upgrading it |
| `windows { perUserInstall }`      | `true`, so installing needs no administrator rights |
| `windows { menuGroup, shortcut }` | A Start menu entry and a desktop shortcut, so the application can be found after installing |
| `iconFile` per OS                 | `.icns` for macOS, `.ico` for Windows, `.png` for Linux; without one, the application shows a generic Java icon |
| `modules(...)`                    | The bundled runtime is built by `jlink` and contains only the listed JDK modules. Check the list with the `suggestRuntimeModules` task: a missing module builds fine and fails at runtime, on the user's machine only |

```kotlin
compose.desktop {
    application {
        mainClass = "com.example.app.MainKt"

        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "Example"
            packageVersion = appVersion
            modules("java.sql", "jdk.unsupported")

            macOS {
                bundleID = "com.example.app"
                iconFile = project.file("icons/app.icns")
            }
            windows {
                upgradeUuid = "3f1c2a8e-5b7d-4c9a-9e61-0d2b7f4a8c15"
                perUserInstall = true
                menuGroup = "Example"
                shortcut = true
                iconFile = project.file("icons/app.ico")
            }
            linux {
                iconFile = project.file("icons/app.png")
            }
        }
    }
}
```

## Versioning

- The version comes from the git tag `vMAJOR.MINOR.PATCH`, passed to Gradle as a property by the release workflow. A local build falls back to a default.
- The installer formats constrain it, so the tag must satisfy both: MSI requires `MAJOR ≤ 255`, `MINOR ≤ 255` and `PATCH ≤ 65535`; DMG requires `MAJOR > 0`. A `0.x` version cannot ship a DMG, so the first release is `1.0.0`.

```kotlin
val appVersion = providers.gradleProperty("appVersion").getOrElse("1.0.0")
```

## Release Workflow

- Releases are built by a **dedicated workflow**, separate from the CI workflow. Verification and delivery have different triggers and different permissions: CI runs on every pull request with read access, a release runs on a tag and writes to the repository's Releases.
- The workflow triggers on a `v*` tag.
- It runs on a matrix — `macos-latest` (arm64), `windows-latest`, `ubuntu-latest` — because `jpackage` cannot cross-build: each OS, and each CPU architecture, builds its own installer. An Intel Mac build needs its own runner; whether to ship one is a project-level choice.
- Each job runs `packageReleaseDistributionForCurrentOS` and attaches its installer to the GitHub Release for the tag. The Release notes come from a file in the repository, so the [signing workaround](#signing) is never forgotten.
- Configuration the build reads from an untracked file (API keys, project identifiers) comes from GitHub secrets, written into that file by the job. It is never committed.

```yaml
name: Release

on:
  push:
    tags: ["v*"]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: gh release create "$GITHUB_REF_NAME" --title "$GITHUB_REF_NAME" --notes-file .github/release-notes.md
        env:
          GH_TOKEN: ${{ github.token }}

  package:
    needs: release
    strategy:
      matrix:
        os: [macos-latest, windows-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        shell: bash
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21
      - run: printf '%s\n' "$LOCAL_PROPERTIES" > local.properties
        env:
          LOCAL_PROPERTIES: ${{ secrets.LOCAL_PROPERTIES }}
      - run: ./gradlew :desktopApp:packageReleaseDistributionForCurrentOS -PappVersion="${GITHUB_REF_NAME#v}"
      - run: gh release upload "$GITHUB_REF_NAME" desktopApp/build/compose/binaries/main-release/*/*
        env:
          GH_TOKEN: ${{ github.token }}
```

The release is created once, before the matrix: three jobs each creating it would race.

## Signing

- Installers are **unsigned by default**. The operating system warns on first launch, and the Release notes carry the one-line workaround for each OS:
    - macOS Gatekeeper: System Settings › Privacy & Security › "Open Anyway".
    - Windows SmartScreen: "More info" › "Run anyway".
- Signing is a **per-project decision, recorded in an ADR**, because it carries a recurring cost: an Apple Developer ID with notarization (the plugin's `notarizeReleaseDmg` task) for macOS, a code-signing certificate for Windows.

## Updates

- Updates are **manual**: the user downloads the new installer from GitHub Releases. On Windows the `upgradeUuid` makes the new MSI upgrade the installed version in place.
- Automatic updates are a **per-project decision, recorded in an ADR**. Compose Desktop provides none, so adopting them means choosing, integrating and maintaining an updater.
