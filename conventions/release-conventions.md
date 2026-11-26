# Release Conventions

This document details how a repository's release workflow authenticates when it writes to the repository: the release pull request, the tag and the GitHub Release. It applies to every repository released with [release-please](https://github.com/googleapis/release-please), application or library.

How an application is packaged and published is in the [Desktop Distribution conventions](desktop-distribution-conventions.md) for a Desktop target, and in each project's own release guide.

## Table of Contents

- [Why a GitHub App](#why-a-github-app)
- [The Shared App](#the-shared-app)
- [Adding a Repository](#adding-a-repository)
- [Workflow](#workflow)
- [Publishing](#publishing)
- [Key Rotation](#key-rotation)

## Why a GitHub App

release-please writes with a token from a GitHub App, never with the workflow's `GITHUB_TOKEN`.

- GitHub starts no workflow from an event the `GITHUB_TOKEN` caused, so that a workflow cannot trigger itself in a loop. A release pull request opened or refreshed with it gets no checks until someone approves them by hand, on every refresh.
- The same rule applies to the tag: a tag pushed with the `GITHUB_TOKEN` starts no tag-triggered workflow, such as the [release workflow](desktop-distribution-conventions.md#release-workflow) of a Desktop application.
- An App token is scoped to the permissions the workflow asks for, and expires after an hour.

A personal access token would lift the same restriction, but it acts as the maintainer rather than as a bot, and it either expires on a date someone has to remember or never expires at all.

## The Shared App

One App, `cyrillrx-release`, serves every repository. It is created once, on the maintainer's account, with:

| Setting                               | Value                                                             |
|---------------------------------------|-------------------------------------------------------------------|
| Webhook                               | Inactive: the App runs no code, it only lends its identity        |
| Repository permissions: Contents      | Read and write: the changelog commit, the tag, the GitHub Release |
| Repository permissions: Pull requests | Read and write: the release pull request                          |
| Repository permissions: Issues        | Read and write: the `autorelease: *` labels on that pull request  |
| Repository permissions: Metadata      | Read-only, imposed by GitHub                                      |
| Every other permission                | No access                                                         |
| Where can this App be installed?      | Only on this account                                              |

Its private key is kept in the maintainer's password manager: GitHub shows it only once, and every new repository needs it.

The App is installed on **selected repositories** only, never on all of them: a repository joins when it starts releasing with release-please. Whoever holds the key can mint a token for any repository the App is installed on, so the installation is the boundary.

## Adding a Repository

1. Add the repository to the App's installation (GitHub settings, Applications, `cyrillrx-release`, Configure).
2. Store the App's client ID, which starts with `Iv`, in the repository variable `RELEASE_APP_CLIENT_ID`, and the private key, the whole `.pem` file, in the repository secret `RELEASE_APP_PRIVATE_KEY`.
3. Run the release-please workflow by hand once: a `Not Found` on the token step means the App is not installed on the repository; an empty `client-id` error means the variable is missing.

## Workflow

The token is minted in the job that runs release-please, and only there:

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions: {}

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - id: app-token
        uses: actions/create-github-app-token@<sha> # v3
        with:
          client-id: ${{ vars.RELEASE_APP_CLIENT_ID }}
          private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
          permission-contents: write
          permission-pull-requests: write
          permission-issues: write

      - uses: googleapis/release-please-action@<sha> # v5
        with:
          token: ${{ steps.app-token.outputs.token }}
```

- `workflow_dispatch` lets a repository check its setup without a commit on `main` ([step 3](#adding-a-repository)).
- The workflow grants the `GITHUB_TOKEN` nothing (`permissions: {}`), and each other job asks for what it needs. The release-please job needs no `GITHUB_TOKEN` permission at all.
- The `permission-*` inputs narrow the token to what release-please uses, even if the App is later granted more.
- Without an `owner` input, the token is valid for the current repository only, whatever else the App is installed on.

## Publishing

The App versions and tags; it does not publish. A build, an upload to a store or a library publication keeps its own credentials in its own job: a store's service account, a package registry's token, or the `GITHUB_TOKEN` with `packages: write`. The App is never granted Packages or Actions permissions for that.

A repository whose release attaches artifacts (installers, binaries) has release-please create the GitHub Release as a draft, with its tag (`"draft": true` and `"force-tag-creation": true` in `release-please-config.json`: a draft alone creates no tag, and `release-please-action` before v4.4.1 ignores `force-tag-creation` without a word). A job that runs after every attaching job publishes it, as the `publish` job of the [Desktop release workflow](desktop-distribution-conventions.md#release-workflow) does, so a failed build leaves no public Release with missing artifacts. Any other repository lets release-please publish the Release directly: nothing else would publish a draft.

## Key Rotation

Generate a new private key on the App, update `RELEASE_APP_PRIVATE_KEY` in every repository the App is installed on, then delete the old key. Both keys stay valid in between, so no release fails during the switch.
