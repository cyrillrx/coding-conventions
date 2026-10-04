# Documentation Conventions

## File naming

- All documentation files use `lowercase-with-hyphens.md`.
- Exception: a file whose name is imposed by tooling keeps it as is — `README.md`, `AGENTS.md`, `CLAUDE.md`, `SKILL.md`, `.github/pull_request_template.md`. GitHub and Claude Code find them by exact name, so renaming one to fit the rule stops it from being found at all.
- Structured documents keep their lowercase prefix: `prd-000-vision.md`, `adr-001-data-model.md`.

## Structured documents

Two document types recur across projects and have a shared skeleton to start from:

| Type                         | Lives in    | Named              | Template                                                                                                          |
|------------------------------|-------------|--------------------|-------------------------------------------------------------------------------------------------------------------|
| Architecture Decision Record | `docs/adr/` | `adr-NNN-title.md` | [`templates/adr-template.md`](https://github.com/cyrillrx/coding-conventions/blob/main/templates/adr-template.md) |
| Product Requirement Document | `docs/prd/` | `prd-NNN-title.md` | [`templates/prd-template.md`](https://github.com/cyrillrx/coding-conventions/blob/main/templates/prd-template.md) |

- Numbers are assigned in order and never reused, including for a document that was withdrawn.
- A superseded document keeps its file and its number; its status line points at the one replacing it. Rewriting or deleting it hides the reasoning that led there.
- `prd-000` is conventionally the product vision. A feature PRD that outgrows a readable length splits into `prd-001a`, `prd-001b`, … rather than gaining sections.
- When an ADR settles a PRD's open question, link it from the PRD instead of deleting the question.

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
- Alignment is measured in display columns, as `wcswidth()` from Python's `wcwidth` package computes them. Prettier 3 measures the same way, so a formatter and a reviewer reach the same file. A Wide or Fullwidth character (Unicode `East_Asian_Width` `W` or `F`) counts two, a combining mark or zero-width character counts zero, any other character counts one. A variation selector `U+FE0F` counts zero itself but makes the character before it count two.
- The reference wins over any renderer. `🔧`, `🕐` and `✅` count two, and so does `⚠️` (`U+26A0` `U+FE0F`). `⛏` (`U+26CF`) and `🏕` (`U+1F3D5`) count one, even where GitHub draws them two columns wide.
- Pad every column to at least three display columns, so a one-character column such as `#` reads `| #   |`. This is a formatting choice for a steady look, not a syntax requirement: GFM accepts a single dash.
- Exception for long prose cells: a column whose widest cell exceeds 120 display columns is not padded, and neither is any column to its right. Each of their cells holds its content with one space on either side, and their separator cells are three dashes; the columns to the left stay aligned. Put a long prose column last so that it is the only one to run free. Padding every row to such a cell pushes the closing pipe off-screen, where alignment helps nobody.

Example:

| Column A    | Column B         |
|-------------|------------------|
| short value | a longer value   |
| another row | yet another cell |
