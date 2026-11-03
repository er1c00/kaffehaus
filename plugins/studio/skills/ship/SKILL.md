---
name: ship
description: Finish an implemented feature slice. Runs the project's tests, then the verifier against the spec's acceptance criteria, the designer for UI changes, and the reviewer. Fixes every BLOCKING finding, ticks off the spec, and commits. Use when a slice is built and the user wants to finish it.
disable-model-invocation: true
argument-hint: "[feature-slug]"
---

# Ship a feature slice

The slice: $ARGUMENTS

You run the checks in order, fix what blocks shipping, and commit. The agents check; you fix. Don't let an agent fix code.

## 0. Find the slice

- **Spec:** `docs/specs/<feature-slug>.md` if a slug was given. Otherwise use the spec this conversation has been working on. If it's still unclear, ask. If there's no spec at all, say so, and offer to write one with `/studio:spec` first.
- **Changes:** run `git status` and `git diff HEAD`. If nothing has changed, stop. If some changes aren't part of this slice, they won't be committed. If you can't tell, ask.
- **UI change?** The designer runs if the changes touch anything users see: pages, components, templates, styles, or interface copy. It needs the app running. Find the dev server command and URL in `CLAUDE.md`, and start the server in the background if it isn't already running.

## 1. Run the tests

Run the `test` command from `studio.config`. If tests fail, fix the code and run them again before going further. If there's no test command, note it in the report.

## 2. Verifier

Delegate to `studio:verifier`. Give it the spec path, the changed files, the test command, and the app URL if there's a UI. Wait for its report: the reviewer should see the tests the verifier adds.

## 3. Designer and reviewer

Run these two in parallel, as two agent calls in one message:
- **`studio:designer`** (UI changes only): the app URL, the pages or screens this slice changed, and the spec path.
- **`studio:reviewer`:** the spec path, the diff to review (`git diff HEAD`, plus any untracked files), and a note that the verifier added tests.

## 4. Fix what blocks shipping

- Keep every finding's original label: **BLOCKING**, **SHOULD FIX**, or **NITPICK**. Don't rename, merge, or soften them. A verifier failure on an acceptance criterion counts as BLOCKING.
- Fix every BLOCKING item yourself. Then re-run the check that raised it: the test command always, the verifier for a failed criterion, and the reviewer or designer for their own findings.
- Stop after two rounds of fixes. If anything BLOCKING is left, report it and ask the user what to do. Don't commit.
- Fix a SHOULD FIX item if it's small and inside this slice. List the rest. List NITPICKs, and fix them only if they're trivial.

## 5. Report

```
Ship report: <feature>
Tests:     <command> → <N passed, M failed>
Verifier:  <verdict>
Designer:  <verdict, or "skipped: no UI change">
Reviewer:  <verdict>

Fixed
- [BLOCKING] <file:line> — <what was wrong> (from <agent>)

Still open
- [SHOULD FIX] <file:line> — <finding> (from <agent>)
- [NITPICK] <file:line> — <finding> (from <agent>)
```

## 6. Commit

1. In the spec, tick each acceptance criterion that's now verified: `- [ ]` becomes `- [x]`. Leave the others unticked, with a short note saying why.
2. If you're on the default branch and the repository has a remote, ask whether to commit on a new branch such as `feat/<feature-slug>`, so it can become a pull request.
3. Stage only this slice's files: its code, its tests, and its spec.
4. Write the commit message:
   - a summary line in the imperative, under 72 characters
   - a body that says what the slice does and which acceptance criteria it meets
   - a last line, `Spec: docs/specs/<feature-slug>.md`
5. Commit, then show the commit hash and message.
6. Never push without asking. If the repository has a GitHub remote and the `gh` CLI is installed, offer to push the branch and open a pull request with `gh pr create`, using the ship report as the body.
