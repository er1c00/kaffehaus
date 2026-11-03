#!/usr/bin/env bash
# SessionStart: in an empty folder with no CLAUDE.md, point Claude at
# /studio:new-project. That skill is user-invoked only, so Claude can't see it
# and would otherwise improvise a setup of its own.
. "$(dirname "$0")/lib.sh"

[ -d "$PROJECT_ROOT" ] || exit 0
[ -f "$PROJECT_ROOT/CLAUDE.md" ] && exit 0
for f in "$PROJECT_ROOT"/*; do
  [ -e "$f" ] && exit 0
done

echo "This folder is empty and has no CLAUDE.md. If the user wants to start a new app or project here, don't scaffold it yourself: tell them to run /studio:new-project, which interviews them and sets up CLAUDE.md, studio.config, and the docs/ folders."
