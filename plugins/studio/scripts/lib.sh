#!/usr/bin/env bash
# Shared helpers for the studio hook scripts. Source this file; don't run it.
#
# Plain bash only (no jq, no bash 4 features), so the hooks run in Git Bash on
# Windows and in the stock bash 3.2 on macOS.

# The JSON that Claude Code sends on stdin.
HOOK_INPUT=$(cat)

# json_str KEY: print the first string value of "KEY" in the hook input, unescaped.
json_str() {
  local re='"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  [[ $HOOK_INPUT =~ $re ]] || return 0
  local s=${BASH_REMATCH[1]}
  s=${s//\\\\/$'\001'}
  s=${s//\\\"/\"}
  s=${s//\\\//\/}
  s=${s//\\n/$'\n'}
  s=${s//\\t/$'\t'}
  s=${s//$'\001'/\\}
  printf '%s' "$s"
}

# json_escape TEXT: print TEXT as the inside of a JSON string.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/}
  s=${s//$'\t'/ }
  printf '%s' "$s"
}

# norm_path PATH: forward slashes, and C:/x becomes /c/x, so paths compare equal.
norm_path() {
  local p=${1//\\//}
  if [[ $p =~ ^([A-Za-z]):/(.*)$ ]]; then
    p="/$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')/${BASH_REMATCH[2]}"
  fi
  printf '%s' "$p"
}

# The project root, normalized. Hooks get CLAUDE_PROJECT_DIR; fall back to the input's cwd.
PROJECT_ROOT=$(norm_path "${CLAUDE_PROJECT_DIR:-$(json_str cwd)}")
PROJECT_ROOT=${PROJECT_ROOT%/}

# rel_path PATH: PATH relative to the project root. Prints nothing if it's outside.
rel_path() {
  local p
  p=$(norm_path "$1")
  case "$p" in
    "$PROJECT_ROOT"/*) printf '%s' "${p#"$PROJECT_ROOT"/}" ;;
  esac
}

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# config_get KEY: print KEY's value from the project's studio.config, or nothing.
config_get() {
  local file="$PROJECT_ROOT/studio.config" line key
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case "$line" in '' | '#'*) continue ;; esac
    [ "${line#*=}" = "$line" ] && continue
    key=$(trim "${line%%=*}")
    if [ "$key" = "$1" ]; then
      trim "${line#*=}"
      return 0
    fi
  done <"$file"
}

# matches_any PATH PATTERNS: true if the file's name, or its path at any depth,
# matches one of the space-separated glob patterns. * also matches /.
matches_any() {
  local path=$1 base=${1##*/} pat
  set -f
  for pat in $2; do
    # shellcheck disable=SC2254
    case "$path" in $pat | */$pat) set +f; return 0 ;; esac
    # shellcheck disable=SC2254
    case "$base" in $pat) set +f; return 0 ;; esac
  done
  set +f
  return 1
}

# deny REASON: block the tool call and tell Claude why.
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(json_escape "$1")"
  exit 0
}

# ask REASON: send the tool call to the user for approval.
ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$(json_escape "$1")"
  exit 0
}
