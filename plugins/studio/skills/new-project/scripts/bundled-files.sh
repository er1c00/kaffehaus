#!/usr/bin/env bash
# Prints the stack guide and every template, each wrapped in <file> tags.
# SKILL.md injects this output when the skill starts, so Claude never has to
# read files from the plugin folder (which sits outside the user's project).
cd "$(dirname "$0")/.." || exit 1

for f in \
  references/stacks.md \
  templates/CLAUDE.md.template \
  templates/studio.config.template \
  templates/docs/product/vision.md \
  templates/docs/product/mvp.md \
  templates/docs/decisions/0001-stack.md \
  templates/docs/decisions/README.md \
  templates/docs/research/README.md \
  templates/docs/specs/README.md
do
  printf '<file path="%s">\n' "${f#templates/}"
  cat "$f"
  printf '</file>\n\n'
done
