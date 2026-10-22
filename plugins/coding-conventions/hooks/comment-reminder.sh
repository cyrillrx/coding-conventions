#!/usr/bin/env bash

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null) || exit 0

case "${file##*.}" in
  kt | kts | java | swift | go | rs | js | ts | c | cpp | gradle) marker='^\s*(//|/\*|\*)' ;;
  sh | py | rb | toml | yaml | yml) marker='^\s*#(?!!)' ;;
  *) exit 0 ;;
esac

added=$(jq -r --arg marker "$marker" '
  (.tool_input.old_string // "" | split("\n")) as $old
  | (.tool_input.new_string // .tool_input.content // "" | split("\n"))[]
  | select(. as $line | $old | any(. == $line) | not)
  | select(test($marker))
  | select(test("^\\s*\\*/\\s*$") | not)
  | select(test("TODO") | not)
' <<<"$input" 2>/dev/null) || exit 0

[ -n "$added" ] || exit 0

jq -n --arg file "$file" --arg lines "$added" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "This edit added comment lines to \($file):\n\($lines)\nCheck each one against §4 Comments of the coding conventions loaded at session start; keep it only if it passes."
  }
}'
