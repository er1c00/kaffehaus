---
name: new-project
description: Set up a new app project for the studio workflow. Interviews you one question at a time, then creates CLAUDE.md, studio.config, and the docs/ tree (product vision and MVP, research, specs, and decisions), and runs git init. Use when starting a new app, or in a folder that has no CLAUDE.md.
disable-model-invocation: true
argument-hint: "[what you want to build]"
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/scripts/bundled-files.sh")
---

# Set up a new project

You're setting up this folder as a project for the studio workflow. First you interview the user, then you create the project's files from the templates. The templates and the stack guide are already included at the end of this skill, under "Bundled files", so you don't need to read any files from the plugin.

The user's opening description, if any: $ARGUMENTS

## 0. Check the folder first

- If `CLAUDE.md` already exists here, stop. Tell the user the project already looks set up, and don't change anything.
- Never overwrite an existing file. If any file you'd create already exists, leave it alone and say so at the end.
- If the folder already has code, this is an existing project. Work out the stack and its format, lint, and test commands from the code, and confirm them with the user instead of asking question 5.

## 1. Interview, one question per message

Ask these questions **one per message**, and wait for the answer before asking the next. Skip any question the user's opening description or an earlier answer already covers. Keep each question short, and give a quick example answer so it's easy to reply.

1. **What is the app?** One or two sentences.
2. **Who is it for?** A specific group of people, and the problem they have today.
3. **What's the one core thing users do in it?** The action the app exists for.
4. **Web, mobile, or both?**
5. **Do you have a preferred stack, or should I recommend one?**
   - To recommend one, use the stack guide under "Bundled files". Recommend one stack with a 2–3 sentence reason tied to their answers, name the runner-up, and ask them to confirm.
   - If they name their own stack, follow the guide's last section.
6. **What else do you picture it doing, now or later?** These answers become the "NOT in the MVP" list, unless the core action can't work without them.

If an answer is vague, ask one short follow-up before moving on. Don't ask about anything else. Pricing, competitors, and demand belong to `/studio:evaluate`.

### Confirm before creating anything

When the interview is done, send one message that summarizes:
- the app, who it's for, the core action, and the platform
- the stack, plus the format, lint, and test commands that will go in `studio.config`
- what will be in the MVP and what won't
- the files you're about to create

Ask the user to confirm or correct it. Create nothing until they confirm.

## 2. Create the files

Take each template from "Bundled files", fill in every `{{PLACEHOLDER}}`, and write the result to the project:

| Template | Write to |
|---|---|
| `CLAUDE.md.template` | `CLAUDE.md` |
| `studio.config.template` | `studio.config` |
| `docs/product/vision.md` | `docs/product/vision.md` |
| `docs/product/mvp.md` | `docs/product/mvp.md` |
| `docs/decisions/0001-stack.md` | `docs/decisions/0001-stack.md` |
| `docs/decisions/README.md` | `docs/decisions/README.md` |
| `docs/research/README.md` | `docs/research/README.md` |
| `docs/specs/README.md` | `docs/specs/README.md` |

Rules for filling templates:
- **Use only what the user told you.** Where you don't know something, write `TBD` and a few words on what's missing. Never invent facts, numbers, users, or competitors.
- **Delete every `<!-- ... -->` comment.** The comments explain what goes in each section. They are not content. Keep the comment in `CLAUDE.md` about scaffolding.
- **Bullets:** placeholders that hold lists (`{{STACK_BULLETS}}`, `{{STACK_CONVENTIONS}}`, `{{MVP_FEATURES}}`, `{{NOT_IN_MVP}}`, `{{ASSUMPTIONS}}`, `{{STACK_ALTERNATIVES}}`, `{{OPEN_QUESTIONS}}`) become `-` bullet lists. Write `{{MVP_FEATURES}}` as a `- [ ]` checklist.
- **The MVP is small.** "In the MVP" holds only what the core action needs end to end, usually 3–5 items. Everything else the user mentioned goes under "NOT in the MVP". It must never be empty: if nothing else came up, list the obvious extras you are deliberately leaving out, such as accounts, payments, or notifications.
- **Assumptions** are the beliefs the idea depends on that nobody has checked, such as "café owners will pay monthly". List 2–4.
- **`CLAUDE.md` stays under 200 lines.** If the stack has no dev server yet, write `TBD` for the command. `{{DEV_URL_NOTE}}` is the local URL in parentheses, or empty.
- **`studio.config`:** use the commands the user confirmed. If the stack has no formatter or linter, leave that value empty rather than guess.
- **Dates:** use today's date, in `YYYY-MM-DD` format.

## 3. Initialize git

Run `git rev-parse --is-inside-work-tree`. If that fails because this isn't a git repository, run `git init`. Don't commit anything.

## 4. Wrap up

Tell the user, briefly:
- which files you created, and any you skipped because they already existed
- each `TBD` you left, so they can fill it in
- that the app code isn't scaffolded yet, and the first build slice will do that

Then offer to run `/studio:evaluate` on the idea next, to check competitors and demand before building.

## Bundled files

These were loaded when the skill started. Each file sits between its `<file>` tags.

!`"${CLAUDE_SKILL_DIR}/scripts/bundled-files.sh"`
