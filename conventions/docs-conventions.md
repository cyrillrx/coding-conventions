# Documentation Conventions

## File naming

- All documentation files use `lowercase-with-hyphens.md`.
- Exception: well-known tooling files (`README.md`, `AGENTS.md`, `CLAUDE.md`) stay uppercase — they are industry-standard names recognized by GitHub, Claude Code, or other tooling.
- Structured documents keep their lowercase prefix: `prd-000-vision.md`, `adr-001-data-model.md`.

## Section separators

- Separate sections with a blank line before the heading. The heading is the separator.
- Do not add a horizontal rule between sections. A `---` on its own line renders a line on top of a break the heading already makes, and doubles the visual noise in long documents.
- The exception is where `---` carries meaning rather than decoration: YAML front matter delimiters, and document separators inside fenced code blocks (a Maestro flow, a multi-document manifest).

## Markdown tables

- Always align table columns with spaces so pipes are vertically aligned.
- Include a separator row (`| --- | --- |`) after the header row.
- Every table cell must have at least one space of padding on each side.

Example:

| Column A    | Column B         |
| ----------- | ---------------- |
| short value | a longer value   |
| another row | yet another cell |
