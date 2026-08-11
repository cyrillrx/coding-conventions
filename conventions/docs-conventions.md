# Documentation Conventions

## File naming

- All documentation files use `lowercase-with-hyphens.md`.
- Exception: well-known tooling files (`README.md`, `AGENTS.md`, `CLAUDE.md`) stay uppercase — they are industry-standard names recognized by GitHub, Claude Code, or other tooling.
- Structured documents keep their lowercase prefix: `prd-000-vision.md`, `adr-001-data-model.md`.

## Section separators

- Separate sections with a blank line before the heading. The heading is the separator.
- Do not add a horizontal rule between sections. A `---` on its own line renders a line on top of a break the heading already makes, and doubles the visual noise in long documents.
- The exception is where `---` carries meaning rather than decoration: YAML front matter delimiters, and document separators inside fenced code blocks (a Maestro flow, a multi-document manifest).

## Line wrapping

- Do not hard-wrap prose. One line per paragraph, per bullet, per table row — rendering and editing both soft-wrap.
- A hard wrap turns a one-word edit into a reflowed paragraph: the diff shows several changed lines instead of one, and review comments anchor to lines the change never touched.
- Column limits belong to code, not to prose. Inside fenced code blocks, follow the language's own convention (120 columns for Kotlin, the `rustfmt` and `gofmt` defaults).

## Markdown tables

- Always align table columns with spaces so pipes are vertically aligned.
- Include a separator row (`| --- | --- |`) after the header row.
- Every table cell must have at least one space of padding on each side. Except for title delimiter.

Example:

| Column A    | Column B         |
|-------------|------------------|
| short value | a longer value   |
| another row | yet another cell |
