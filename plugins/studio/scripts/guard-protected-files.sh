#!/usr/bin/env bash
# PreToolUse on Write|Edit: protect secrets, keys, and lockfiles.
#
# In the main session the edit goes to the user for approval, so it happens only
# if they explicitly agree. Subagents are always blocked.
. "$(dirname "$0")/lib.sh"

file=$(json_str file_path)
[ -n "$file" ] || exit 0
base=$(norm_path "$file")
base=${base##*/}
lower=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')

case "$lower" in
  .env.example | .env.sample | .env.template) exit 0 ;;
  .env* | *secret* | *.pem) kind="may contain secrets or keys" ;;
  package-lock.json | npm-shrinkwrap.json | yarn.lock | pnpm-lock.yaml | bun.lock | bun.lockb | \
    poetry.lock | uv.lock | pipfile.lock | cargo.lock | gemfile.lock | composer.lock | go.sum)
    kind="is a lockfile, which the package manager should update" ;;
  *) exit 0 ;;
esac

if [ -n "$(json_str agent_type)" ]; then
  deny "$base $kind. Subagents may not edit it. Report the change you need instead."
fi
ask "$base $kind. The studio plugin protects it: edit it only if the user explicitly asked for this change."
