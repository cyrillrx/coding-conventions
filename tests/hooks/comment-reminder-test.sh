#!/usr/bin/env bash
set -u

hook="$(dirname "$0")/../../plugins/coding-conventions/hooks/comment-reminder.sh"
failures=0

write() { jq -n --arg f "$1" --arg c "$2" '{tool_name: "Write", tool_input: {file_path: $f, content: $c}}'; }
edit() { jq -n --arg f "$1" --arg o "$2" --arg n "$3" '{tool_name: "Edit", tool_input: {file_path: $f, old_string: $o, new_string: $n}}'; }

expect_reminder() {
  local name=$1 input=$2 expected=$3 output
  output=$("$hook" <<<"$input")
  if jq -e --arg e "$expected" '.hookSpecificOutput.additionalContext | contains($e)' <<<"$output" >/dev/null 2>&1; then
    echo "ok   $name"
  else
    echo "FAIL $name: expected a reminder listing '$expected', got '$output'"
    failures=$((failures + 1))
  fi
}

expect_silence() {
  local name=$1 input=$2 output status
  output=$("$hook" <<<"$input")
  status=$?
  if [ -z "$output" ] && [ "$status" -eq 0 ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: expected silence and exit 0, got status $status and '$output'"
    failures=$((failures + 1))
  fi
}

expect_reminder "a written Kotlin file with a KDoc" \
  "$(write Foo.kt $'/** Rolls the dice. */\nfun roll() = 4')" "/** Rolls the dice. */"
expect_reminder "an edit adding a line comment" \
  "$(edit Foo.kt 'val a = 1' $'// Keeps a positive.\nval a = 1')" "// Keeps a positive."
expect_reminder "a written Python file with a hash comment" \
  "$(write tool.py $'#!/usr/bin/env python3\n# Reads the input.\nprint(1)')" "# Reads the input."
expect_silence "an edit keeping an existing comment" \
  "$(edit Foo.kt $'// Kept.\nval a = 1' $'// Kept.\nval a = 2')"
expect_silence "a shebang alone" "$(write tool.sh $'#!/usr/bin/env bash\necho hi')"
expect_silence "a KDoc closing line alone" "$(edit Foo.kt 'x' $'x\n */')"
expect_silence "a Markdown file" "$(write notes.md '// not code')"
expect_silence "a TODO" "$(write Foo.kt $'// TODO(#12): drop once migrated\nval a = 1')"
expect_silence "code without comments" "$(write Foo.kt 'val url = "https://example.com"')"
expect_silence "invalid JSON" "not json"

exit $((failures > 0))
