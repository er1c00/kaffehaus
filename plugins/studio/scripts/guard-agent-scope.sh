#!/usr/bin/env bash
# PreToolUse: keep studio's subagents inside their limits.
#
#   studio:verifier  Write/Edit only test files (studio.config `test_files`).
#                    Bash: no file deletes, git changes, package installs, in-place
#                    edits, or redirects into non-test files.
#   studio:designer  Write/Edit only inside prototypes/.
#   studio:reviewer  Bash: read-only commands only.
#   designer and verifier: no screenshot filenames, which would write into the project.
#
# The Bash checks are best effort. They read the command as text, not as a shell
# would, and refuse anything they can't tell is safe. The reviewer catches the rest.
. "$(dirname "$0")/lib.sh"

agent=$(json_str agent_type)
case "$agent" in studio:verifier | studio:designer | studio:reviewer) ;; *) exit 0 ;; esac
tool=$(json_str tool_name)

DEFAULT_TEST_FILES='*.test.* *.spec.* test_*.py *_test.* conftest.py tests/* test/* __tests__/* e2e/*'
test_patterns() {
  local p
  p=$(config_get test_files)
  printf '%s' "${p:-$DEFAULT_TEST_FILES}"
}

is_test_path() {  # is_test_path PATH (absolute, or relative to the project root)
  local p=$1 rel
  case "$p" in /* | [A-Za-z]:* | \\*) rel=$(rel_path "$p") ;; *) rel=${p#./} ;; esac
  [ -n "$rel" ] && matches_any "$rel" "$(test_patterns)"
}

# Split a command into its simple commands, one per line. Quotes aren't
# understood, so a separator inside quotes splits too, which only ever makes
# the checks stricter.
segments() {
  local c=$1
  c=${c//&&/$'\n'}
  c=${c//||/$'\n'}
  c=${c//;/$'\n'}
  c=${c//|/$'\n'}
  printf '%s\n' "$c"
}

# Drop the bodies of heredocs (<<EOF ... EOF). They're data, not commands, and
# text such as "a -> b" in a body would otherwise look like a redirect.
strip_heredocs() {
  local line delim="" out="" re='<<-?[[:space:]]*["'\'']?([A-Za-z_][A-Za-z0-9_]*)'
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$delim" ]; then
      [ "$(trim "$line")" = "$delim" ] && delim=""
      continue
    fi
    out+="$line"$'\n'
    [[ ${line//<<</ } =~ $re ]] && delim=${BASH_REMATCH[1]}
  done < <(printf '%s\n' "$1")
  printf '%s' "$out"
}

# Print the first words of a segment, skipping leading VAR=value assignments.
words() {
  local s
  s=$(trim "$1")
  while [[ $s =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do s=${BASH_REMATCH[1]}; done
  printf '%s' "$s"
}

# Remove redirects that don't write files: 2>&1, >&2, and anything sent to /dev/null.
strip_safe_redirects() {
  local c=$1
  c=$(printf '%s' "$c" | sed -E 's/[0-9]*>&[0-9]//g; s/(&|[0-9]*)>>?[[:space:]]*\/dev\/null//g')
  printf '%s' "$c"
}

reviewer_segment_ok() {
  local s
  s=$(words "$1")
  [ -n "$s" ] || return 0
  set -f
  # shellcheck disable=SC2086
  set -- $s
  set +f
  case "$1" in
    cd | pwd | ls | cat | head | tail | wc | grep | rg | file | stat | echo | printf | cut | tr | diff | true | which | type) return 0 ;;
    sort) case " $* " in *" -o"* | *" --output"*) return 1 ;; esac; return 0 ;;
    find) case " $* " in *" -delete"* | *" -exec"* | *" -ok"* | *" -fprint"* | *" -fls"*) return 1 ;; esac; return 0 ;;
    git)
      shift
      while [ $# -gt 0 ]; do
        case "$1" in --no-pager | -P) shift ;; -C) shift 2 ;; *) break ;; esac
      done
      case " $* " in *" --output"*) return 1 ;; esac
      case "$1" in
        diff | log | show | status | blame | ls-files | ls-tree | rev-parse | merge-base | describe | shortlog | cat-file | grep | rev-list | name-rev | show-ref) return 0 ;;
        branch)
          shift
          for a in "$@"; do
            case "$a" in -a | -r | -v | -vv | --all | --remotes | --verbose | --list | --show-current | --no-color) ;; *) return 1 ;; esac
          done
          return 0 ;;
      esac
      return 1 ;;
  esac
  return 1
}

verifier_segment_ok() {
  local s last
  s=$(words "$1")
  [ -n "$s" ] || return 0
  set -f
  # shellcheck disable=SC2086
  set -- $s
  set +f
  case "$1" in
    rm | rmdir | mv | unlink | shred | tee | del) return 1 ;;
    cp)
      for last in "$@"; do :; done
      is_test_path "$last" || return 1 ;;
    sed | perl) case " $* " in *" -i"* | *" --in-place"*) return 1 ;; esac ;;
    git)
      shift
      while [ $# -gt 0 ]; do
        case "$1" in --no-pager | -P) shift ;; -C) shift 2 ;; *) break ;; esac
      done
      case "$1" in
        commit | push | pull | checkout | switch | reset | stash | clean | rebase | merge | restore | rm | mv | add | tag | \
          cherry-pick | revert | am | apply | branch | worktree | config | init | clone | -c) return 1 ;;
      esac ;;
    npm | pnpm | yarn | bun)
      case "$2" in install | i | ci | add | uninstall | remove | rm | un | update | up | upgrade | link) return 1 ;; esac ;;
    pip | pip3) case "$2" in install | uninstall | download) return 1 ;; esac ;;
    python | python3 | py) case " $* " in *" -m pip install"* | *" -m pip uninstall"*) return 1 ;; esac ;;
    uv) case "$2" in add | remove | sync | lock | pip) return 1 ;; esac ;;
    poetry) case "$2" in add | remove | install | update | lock) return 1 ;; esac ;;
    cargo) case "$2" in add | remove | install | update) return 1 ;; esac ;;
    go) case "$2" in get | install | mod) return 1 ;; esac ;;
    brew | apt | apt-get | choco | winget | scoop) return 1 ;;
  esac
  return 0
}

# Every remaining redirect must write to a test file.
verifier_redirects_ok() {
  local c=$1 re='>>?[[:space:]]*([^[:space:];&|<>]+)'
  while [[ $c =~ $re ]]; do
    is_test_path "${BASH_REMATCH[1]//[\"\']/}" || return 1
    c=${c#*"${BASH_REMATCH[0]}"}
  done
  return 0
}

case "$agent:$tool" in
  studio:verifier:Write | studio:verifier:Edit)
    file=$(json_str file_path)
    shown=$(rel_path "$file")
    is_test_path "$file" ||
      deny "The verifier may edit test files only, and ${shown:-$file} is not one (studio.config test_files: $(test_patterns)). Leave the code under test alone: report the bug with a failing test and a repro instead."
    ;;

  studio:designer:Write | studio:designer:Edit)
    rel=$(rel_path "$(json_str file_path)")
    case "$rel" in
      prototypes/*) ;;
      *) deny "The designer may write only inside prototypes/. Report the change you'd make to the app's files instead, with file:line, and the main session will apply it." ;;
    esac
    ;;

  studio:reviewer:Bash)
    cmd=$(strip_heredocs "$(json_str command)")
    case "$cmd" in *'`'* | *'$('* | *'<('* | *'>('*) deny "The reviewer is read-only: command substitution isn't allowed. Run one plain read-only command at a time." ;; esac
    case "$(strip_safe_redirects "$cmd")" in *'>'*) deny "The reviewer is read-only and may not redirect output into files." ;; esac
    while IFS= read -r seg; do
      reviewer_segment_ok "$seg" ||
        deny "The reviewer is read-only. Allowed: git diff/log/show/status/blame/ls-files and similar read-only git commands, plus ls, cat, head, tail, wc, grep, find, cd. Blocked: $(trim "$seg")"
    done <<EOF
$(segments "$cmd")
EOF
    ;;

  studio:verifier:Bash)
    cmd=$(strip_heredocs "$(json_str command)")
    verifier_redirects_ok "$(strip_safe_redirects "$cmd")" ||
      deny "The verifier may write only to test files, and this command redirects output into another file."
    while IFS= read -r seg; do
      verifier_segment_ok "$seg" ||
        deny "The verifier may run tests and read-only commands, but not delete or move files, change git state, install packages, or edit non-test files. Blocked: $(trim "$seg")"
    done <<EOF
$(segments "$cmd")
EOF
    ;;

  studio:designer:mcp__plugin_studio_playwright__browser_take_screenshot | studio:verifier:mcp__plugin_studio_playwright__browser_take_screenshot)
    [ -z "$(json_str filename)" ] ||
      deny "Don't pass a filename to the screenshot tool: with one, the file lands in the project and you don't see the image. Call it again without a filename."
    ;;
esac
exit 0
