# Documentation Conventions

## File naming

- All documentation files use `lowercase-with-hyphens.md`.
- Exception: well-known tooling files (`README.md`, `AGENTS.md`, `CLAUDE.md`) stay uppercase — they are industry-standard names recognized by GitHub, Claude Code, or other tooling.
- Structured documents keep their lowercase prefix: `prd-000-vision.md`, `adr-001-data-model.md`.

## Section separators

- Separate sections with a blank line before the heading. The heading is the separator.
- Do not add a horizontal rule between sections. `\n---\n` renders a line on top of a break the
  heading already makes, and doubles the visual noise in long documents.
- The exception is the one place `---` carries meaning: YAML front matter delimiters at the very top
  of a file.

## Markdown tables

- Always align table columns with spaces so pipes are vertically aligned.
- Include a separator row (`| --- | --- |`) after the header row.
- Every table cell must have at least one space of padding on each side.

Example:

| Column A    | Column B         |
| ----------- | ---------------- |
| short value | a longer value   |
| another row | yet another cell |
