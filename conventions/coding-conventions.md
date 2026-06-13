# General Coding Conventions

This document outlines the core Clean Code principles for the project.
These rules apply across all technologies (Kotlin, Rust, Go, etc.).

## 1. Code Quality & Maintainability

- **Readability**: Write code that is easy to understand and maintain. Readability and maintainability almost always take precedence over performance.
- **Consistency**: Adhere to established coding conventions and architectural patterns.
- **Avoid premature optimization**: Write clean code first; optimize only when proven necessary by profiling.
- **Security**: Prioritize security in all aspects of development, especially for backend services. Never trust client input without validation.
- **Documentation**: Document complex logic, public APIs, and architectural decisions.

## 2. Meaningful Names

- **Reveal Intent**: Names must explain why a variable exists, what it does, and how to use it. If a name needs a comment, it is not clear enough.
- **Class Names**: Use nouns or noun phrases like `Campaign` or `CharacterProfile`. Try to avoid vague words like `Manager`, `Processor`, or `Data`.
- **Method Names**: Use verbs or verb phrases like `postPayment`, `save`, or `deletePage`.
- **Be Explicit**: Avoid abbreviations and single letters. Do not use misleading names (e.g., avoid `accountList` if it is actually a `Set`).

## 3. Functions

- **Keep them Small**: Functions should rarely exceed 20 lines.
- **Do One Thing (SRP)**: If you can extract a block into a well-named function, your current function is doing too much.
- **One Level of Abstraction**: Do not mix high-level concepts with low-level details in the same function.
- **Limit Arguments**: Aim for 0 to 2 arguments. If you need more, group them into a dedicated data class or struct.
- **Command Query Separation (CQS)**: A function should either change state (Command) or return data (Query), never both.
- **No Hidden Side Effects**: Do exactly what the function name promises and nothing else.

## 4. Comments

- **Express Intent in Code**: Code tells the truth, while comments often get outdated and lie. Refactor your code to make it self-explanatory instead of adding a comment.
- **Explain "Why", Not "What"**: Only write inline comments to explain business rules, context, or unavoidable hacks.
- **Good Comments**: Public API contracts (KDoc/Rustdoc), TODOs, legal headers.
- **Bad Comments**: Redundant explanations, commented-out code (delete it, Git remembers), changelogs.

## 5. Error Handling

- **Fail Fast**: Validate inputs immediately. Halt execution or return errors as soon as an invalid state is detected.
- **Use Exceptions/Results**: Use idiomatic error handling (Kotlin Exceptions, Rust `Result`) instead of returning arbitrary error codes.
- **Isolate Error Handling**: Extract `try/catch` or `match` blocks into their own functions. Error handling is "one thing".
- **Provide Context**: Include enough information in error messages to easily trace the source of the failure.

## 6. Organization & Formatting

- **Automated Formatting**: Rely 100% on formatters (`ktlint`, `rustfmt`, `gofmt`). If the CI pipeline passes, the formatting is correct. No debates.
- **Newspaper Metaphor**: Put high-level concepts at the top of the file, increasing detail as you read downward.
- **Keep Related Code Close**: Group related concepts vertically. Declare local variables right before their first use.
- **Early Return Spacing**: Always leave a blank line after an early return (guard clause) to visually separate the guard from the function body.

## 7. Objects and Data Structures

- **Favor Immutability**: Make data structures immutable by default to prevent side-effect bugs and ensure thread safety.
- **Law of Demeter**: Don't chain calls through internal properties (`a.getB().getC().doSomething()`). Modules shouldn't know the inner workings of the objects they manipulate.
- **Data Abstraction**: Hide internal implementation details. Expose interfaces that allow users to manipulate the essence of the data.

## 8. Testing

- **Comprehensive Coverage**: Write comprehensive tests to ensure correctness and prevent regressions.
- **F.I.R.S.T. Principles**: Tests should be Fast, Independent, Repeatable, Self-Validating, and Timely.
- **Clear Assertions**: Strive to have a single logical assertion or concept per test function to make failures easy to diagnose.
