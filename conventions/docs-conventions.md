# Documentation Conventions

## File naming

- All documentation files use `lowercase-with-hyphens.md`.
- Exception: well-known tooling files (`README.md`, `AGENTS.md`, `CLAUDE.md`) stay uppercase — they are industry-standard names recognized by GitHub, Claude Code, or other tooling.
- Structured documents keep their lowercase prefix: `prd-000-vision.md`, `adr-001-data-model.md`.

## Markdown tables

- Always align table columns with spaces so pipes are vertically aligned.
- Include a separator row (`| --- | --- |`) after the header row.
- Every table cell must have at least one space of padding on each side.

Example:

| Column A    | Column B         |
| ----------- | ---------------- |
| short value | a longer value   |
| another row | yet another cell |
