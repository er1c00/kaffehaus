---
name: spec
description: Write a small, testable spec for one feature before any code is written. Clarifies the feature with the user, then writes docs/specs/<feature-slug>.md with the user story, the vertical slice (UI, logic, data, and tests), acceptance criteria as a checklist, non-goals, and open questions, and proposes a short implementation plan to confirm. Use whenever the user wants to build, add, or change a feature.
argument-hint: "[the feature to spec]"
---

# Spec a feature

The feature: $ARGUMENTS

This skill produces a spec and a plan. **Don't write any code here.** Coding starts only after the user confirms the plan.

## 1. Gather context

- Read `CLAUDE.md`, `docs/product/vision.md`, and `docs/product/mvp.md` if they exist.
- If the feature is listed under "NOT in the MVP", say so and ask whether to go ahead anyway.
- Check `docs/specs/` for a spec that overlaps. If one does, ask whether to extend it or write a new one.
- Look at the code this feature touches, so the spec fits what exists. For a large codebase, use the Explore agent.

## 2. Clarify

Ask the user only what you can't work out yourself: one question per message, three at most. Good questions cover:
- the expected behavior, including what happens with empty, invalid, or extreme input
- anything that sounds like it belongs in this feature but might not

If the request is already clear, skip straight to writing.

## 3. Write the spec

Save it to `docs/specs/<feature-slug>.md` in this format:

```markdown
# <Feature name>

## User story
As <who>, I want <what>, so that <why>.

## Vertical slice
<What changes in each layer, end to end. Leave out layers this feature doesn't touch.>
- **UI:** <screens, components, or pages>
- **Logic:** <functions or modules>
- **Data:** <storage, schema, or API changes>
- **Tests:** <what gets tested, and where the tests live>

## Acceptance criteria
- [ ] <one observable, testable behavior, with concrete values>

## Non-goals
- <what this spec deliberately doesn't do>

## Open questions
- <anything undecided, or "None">
```

Rules for acceptance criteria:
- Each one is a single behavior that a test or a person in a browser can check, with concrete values. For example, "Splitting $100 between 3 people shows $33.34, $33.33, $33.33", not "splitting works".
- Include the error and edge cases that matter to the user.
- **More than about 7 criteria means the spec is too big.** Propose splitting it. Write the first spec, and list the others as follow-ups.

## 4. Check the scope (optional)

If the spec is large, risky, or the user asks for it, delegate to `studio:skeptic`: paste in the spec and ask what in it isn't needed to deliver the user story. Trim the spec based on what's useful in the answer.

## 5. Propose the implementation plan

In chat (not in the spec file), give a short numbered plan:
- the files to create or change, in order
- the tests that will prove each acceptance criterion

Ask the user to confirm the plan or change it. Don't start coding until they confirm. When the slice is built, finish it with `/studio:ship <feature-slug>`.
