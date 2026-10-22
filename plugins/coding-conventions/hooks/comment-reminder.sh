#!/usr/bin/env bash

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null) || exit 0

docstring='(?!)'
case "${file##*.}" in
  kt | kts | java | swift | go | rs | js | jsx | ts | tsx | c | cpp | gradle) marker='^\s*(//|/\*|\*(\s|/|$))|\S\s+(//|/\*)(\s|$)' ;;
  py)
    marker='^\s*#(?!!)|\S\s+#(\s|$)'
    docstring='^\s*[rRuUbB]?("{3}|\x27{3})'
    ;;
  sh | rb | toml | yaml | yml) marker='^\s*#(?!!)|\S\s+#(\s|$)' ;;
  *) exit 0 ;;
esac

# A docstring is the first statement of a module, a def or a class: the triple quotes of any other
# line open or close an ordinary string.
added=$(jq -r --arg marker "$marker" --arg docstring "$docstring" '
  def stripped: sub("^\\s+"; "") | sub("\\s+$"; "");
  (.tool_input.old_string // "" | split("\n") | map(stripped)) as $old
  | (.tool_input.new_string // .tool_input.content // "" | split("\n")) as $new
  | range(0; $new | length) as $i
  | $new[$i]
  | select(stripped as $line | $old | any(. == $line) | not)
  | select(test($marker) or (test($docstring) and ($i == 0 or ($new[$i - 1] | test(":\\s*$")))))
  | select(test("^\\s*\\*/\\s*$") | not)
  | select(test("(//|/\\*|^\\s*\\*|#)\\s*TODO") | not)
' <<<"$input" 2>/dev/null) || exit 0

[ -n "$added" ] || exit 0

jq -n --arg file "$file" --arg lines "$added" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "This edit added comment lines to \($file):\n\($lines)\nCheck each one against §4 Comments of the coding conventions loaded at session start; keep it only if it passes. Tool directives (build tags, linter or type-checker pragmas) are not comments: leave them."
  }
}'
