#!/usr/bin/env bash
# PostToolUse on Write|Edit: run the project's format and lint commands on the
# file Claude just edited, and show Claude any problems.
#
# Reads `format`, `format_files`, `lint`, and `lint_files` from studio.config in
# the project root. Does nothing if there's no studio.config.
. "$(dirname "$0")/lib.sh"

[ -f "$PROJECT_ROOT/studio.config" ] || exit 0
rel=$(rel_path "$(json_str file_path)")
[ -n "$rel" ] && [ -f "$PROJECT_ROOT/$rel" ] || exit 0

# The file path goes into the command single-quoted, so odd names can't inject shell code.
quoted="'${rel//\'/\'\\\'\'}'"
report=""

run_check() {
  local name=$1 cmd patterns out status
  cmd=$(config_get "$name")
  [ -n "$cmd" ] || return 0
  patterns=$(config_get "${name}_files")
  if [ -n "$patterns" ] && ! matches_any "$rel" "$patterns"; then return 0; fi
  cmd=${cmd//\{file\}/$quoted}
  out=$(cd "$PROJECT_ROOT" && bash -c "$cmd" 2>&1 </dev/null)
  status=$?
  if [ "$status" -ne 0 ]; then
    report+="studio.config $name failed on $rel (exit $status): $cmd"$'\n'
    report+="$(printf '%s\n' "$out" | head -n 40)"$'\n\n'
  fi
}

run_check format
run_check lint

if [ -n "$report" ]; then
  printf '%sFix these problems, or tell the user if a tool is missing.\n' "$report" >&2
  exit 2
fi
exit 0
