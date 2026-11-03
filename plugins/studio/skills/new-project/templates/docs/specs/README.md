# Specs

One file per feature, written with `/studio:spec` before any code. The verifier tests against it and the reviewer reviews against it.

- **Name:** `<feature-slug>.md`.
- **Sections:** User story, Vertical slice (UI, logic, data, and tests, end to end), Acceptance criteria as a `- [ ]` checklist, Non-goals, and Open questions.
- **Size:** keep specs small. More than about 7 acceptance criteria usually means the spec should be split.
- **Done:** `/studio:ship` ticks off each criterion once it's verified.
