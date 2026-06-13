# Go Backend Conventions

This document outlines the architectural patterns, coding conventions, and best practices for Go services.

It builds on the general [Clean Code principles](coding-conventions.md).

## 1. Tech Stack & Dependency Management

- **Language**: Go (latest stable version).
- **Package Manager**: Go Modules (`go.mod` / `go.sum`).
- **Router**: `github.com/go-chi/chi/v5` (lightweight, idiomatic, stdlib-compatible).
- **Dependency Management**: Keep `go.mod` and `go.sum` committed for reproducible builds.

## 2. Architecture

### Service Architecture

- Follow a layered approach: **Handlers → Store interface → Store implementation**.
- Keep a `Store` interface as the sole boundary between HTTP handlers and data access. This decouples routing logic from data-source details and allows swapping the backing store (JSON → DB) without touching handlers.
- Use `internal/` packages to enforce encapsulation within the module.

### Package Layout

```
cmd/
└── server/
    └── main.go          ← entrypoint: wires store + router, starts server
internal/
├── handler/             ← HTTP handler functions (one file per resource)
├── model/               ← response DTOs + raw JSON structs (one file per resource)
└── store/
    ├── store.go         ← Store interface
    └── json_store.go    ← JSON file-backed implementation
```

## 3. Coding Conventions

- **Formatting**: Always run `gofmt` (enforced by `go vet` and most editors).
- **Linting**: Use `go vet ./...` as a minimum. Consider `golangci-lint` for stricter checks.
- **Error Handling**: Always handle errors explicitly. Use `fmt.Errorf("context: %w", err)` for wrapping.
- **Naming**: Follow standard Go conventions — exported names are PascalCase, unexported are camelCase.
- **Comments**: Document all exported types and functions with a `//` comment starting with the identifier name.

## 4. API Design

- Follow RESTful principles with resource-based URL paths (e.g. `/compendium/spells`).
- Return `application/json` with consistent camelCase field names.
- Use `json.NewEncoder(w).Encode(data)` for streaming responses.

## 5. Testing

- **Unit Tests**: Place test files alongside the code they test (`*_test.go`).
- **Integration Tests**: Test the full HTTP stack using `net/http/httptest`.
- Run with `go test ./...`.

## 6. CI & Policies

Refer to [`git-and-collaboration.md`](../collaboration/git-and-collaboration.md) for general CI policies.

Go-specific CI requirements:
- `go build ./...` must pass.
- `go test ./...` must pass.
- `go vet ./...` must pass.
