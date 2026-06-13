# Rust Backend Conventions

This document outlines the architectural patterns, coding conventions, and best practices for Rust services.

It builds on the general [Clean Code principles](coding-conventions.md).

## 1. Tech Stack & Dependency Management

- **Language**: Rust (latest stable edition).
- **Package Manager**: Cargo.
- **Web Framework**: Axum (for web services).
- **Asynchronous Runtime**: Tokio.
- **Database Client**: `sqlx`.
- **Dependency Management**: Manage dependencies via `Cargo.toml`.

## 2. Architecture

### Service Architecture

- Design services to be modular and focused on single responsibilities.
- Consider a layered approach (e.g. Handlers, Services/Business Logic, Repositories).
- Utilize Rust's ownership and borrowing system to ensure memory safety and concurrency without data races.

## 3. Coding Conventions

- **Code Formatting**: Adhere to `rustfmt` for consistent code formatting.
- **Linting**: Use `clippy` to catch common mistakes and improve Rust code.
- **Error Handling**: Favor `Result` and `Option` for explicit error handling over panics. Use custom error types where appropriate.
- **Concurrency**: Utilize `async/await` and Rust's concurrency primitives (`Arc`, `Mutex`, `RwLock`, channels) responsibly.
- **Documentation**: Write clear and comprehensive `///` documentation comments for public APIs.

## 4. API Design

- Design RESTful APIs where applicable, following the same principles as other backend services.
- Ensure clear data serialization/deserialization, typically using `serde`.

## 5. Testing

- **Unit Tests**: Write unit tests for individual functions and modules, typically inline with the code.
- **Integration Tests**: Create integration tests in the `tests` directory to test interactions between components or with external services.
- **Property-Based Testing**: Consider libraries like `proptest` for robust testing of complex logic.

## 6. Performance & Safety

- **Benchmarking**: Use Rust's built-in benchmarking tools or `criterion` for performance-critical sections.
- **Unsafe Rust**: Minimize the use of `unsafe` blocks and ensure thorough justification and review when necessary.
- **Memory Management**: Leverage Rust's compile-time memory safety. Avoid common pitfalls like excessive cloning.

## 7. CI & Policies

Refer to [`git-and-collaboration.md`](../collaboration/git-and-collaboration.md) for general CI policies (warnings as errors, PR requirements, security scans).

Rust-specific CI requirements:
- `cargo build` and `cargo test` must pass for all pull requests.
- `clippy` checks must be integrated into the CI pipeline.
- Run `cargo audit` to check for known vulnerabilities in dependencies.
