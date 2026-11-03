# plan.md — "studio": a reusable Claude Code plugin for building apps

## What we're building

A Claude Code plugin called `studio`, hosted in a GitHub repo called `kaffehaus`, that gives every project the same workflow from idea to shipped app: validate → define → design → build in slices → verify → review → ship.

It has two layers:

1. **The plugin**: agents, skills, hooks, and MCP config that behave the same in every project. Improve it once, and every project gets the update.
2. **The starter**: a `/new-project` skill inside the plugin that scaffolds each new project's own files (CLAUDE.md, `docs/` folders) by interviewing the user.

The plugin is stack-neutral. Anything stack-specific (format, lint, and test commands) lives in each project's own files, which `/new-project` creates.

## Decisions already made (don't re-debate these)

- **Claude Code only.** No custom orchestration app, no OpenCode, no API billing. Everything runs inside Claude Code on the user's subscription.
- **No CEO, CTO, or Programmer agents.** The main session is the coordinator and the programmer, and the user is the boss. Architecture decisions are recorded in `docs/decisions/`, not delegated to an agent.
- **An agent exists only if it needs isolated context, different tool permissions, or an independent viewpoint.** Everything else is a skill or a CLAUDE.md line.
- **Ideas and code for one app live in the same project**, so agents building features can read why each feature exists.
- **Guardrails go in hooks, not instructions.** Anything that must hold every time is enforced by a hook.
- **Plugin subagents ignore `hooks`, `mcpServers`, and `permissionMode` in their frontmatter.** Put hooks in the plugin's `hooks/hooks.json` and MCP servers in the plugin's `.mcp.json`. `tools`, `disallowedTools`, `model`, and `skills` in agent frontmatter still work.

## Repo structure

```
kaffehaus/
├── .claude-plugin/
│   └── marketplace.json            # lists the studio plugin; source "./plugins/studio"
├── README.md                       # how to install, update, and use
└── plugins/
    └── studio/
        ├── .claude-plugin/
        │   └── plugin.json         # name: "studio" (must match the marketplace entry name)
        ├── agents/
        │   ├── researcher.md
        │   ├── skeptic.md
        │   ├── designer.md
        │   ├── verifier.md
        │   └── reviewer.md
        ├── skills/
        │   ├── new-project/
        │   │   ├── SKILL.md
        │   │   └── templates/
        │   │       ├── CLAUDE.md.template
        │   │       ├── studio.config.template   # project's format/lint/test commands
        │   │       └── docs/                    # skeleton files for each docs folder
        │   ├── evaluate/SKILL.md
        │   ├── spec/SKILL.md
        │   └── ship/SKILL.md
        ├── hooks/
        │   └── hooks.json
        ├── scripts/                # scripts the hooks call
        │   ├── post-edit-check.sh
        │   └── guard-protected-files.sh
        └── .mcp.json               # browser automation (e.g. Playwright MCP); GitHub optional
```

## The five agents

Write each description so the main session knows exactly **when** to delegate to it. Descriptions are how delegation gets decided, so be specific and a little pushy.

### researcher
- **Purpose:** investigate questions (codebase, docs, libraries, competitors, markets, pricing) and return only the findings, keeping the main session's context clean.
- **Tools:** read-only plus web search and fetch. No Edit or Write.
- **Output:** a short findings summary with sources and file paths, plus an explicit "what I couldn't confirm" section.
- **Note:** check whether the built-in Explore agent already covers codebase-only questions. This agent exists mainly for web and market research and for following the project's `docs/research/` conventions.
- **Model:** sonnet.

### skeptic
- **Purpose:** red-team ideas, MVP scope, and plans. Its only job is to find reasons something fails: who already does it, why customers won't pay, what's harder than it looks, and what's in the MVP that doesn't need to be.
- **Tools:** read-only plus web search (to check for competitors).
- **Output:** the top risks ranked by severity, each with "what evidence would change my mind," then the single cheapest real-world test to run next. It must not soften conclusions to be agreeable.
- **Model:** opus.

### designer
- **Purpose:** look at the rendered UI in a real browser and critique layout, visual hierarchy, consistency, responsiveness (mobile and desktop widths), and accessibility basics (contrast, focus states, touch target size, alt text). It can also produce wireframes and clickable throwaway prototypes when asked.
- **Tools:** read code, plus the browser MCP from the plugin's `.mcp.json`. It may write only inside `prototypes/` (see the hooks section).
- **Output:** findings with screenshots or descriptions, ranked BLOCKING / SHOULD FIX / NITPICK.
- **Model:** sonnet.

### verifier
- **Purpose:** write and run tests for each feature slice. Its job is to try to *break* the feature, not to confirm it works. It checks every acceptance criterion in the spec.
- **Tools:** read, run commands, and edit **test files only** (enforced by a hook, see below).
- **Output:** what was tested, what passed, what failed (with reproduction steps), and which acceptance criteria are uncovered.
- **Model:** sonnet.

### reviewer
- **Purpose:** senior code review in a fresh context. It didn't write the code, so it reviews skeptically.
- **Tools:** read-only, using `disallowedTools: Edit, Write`.
- **Process:** read the spec in `docs/specs/` and the git diff, check that every acceptance criterion is actually met, look for bugs, edge cases, security issues, and dead code, and flag anything more complex than it needs to be.
- **Output:** findings as BLOCKING / SHOULD FIX / NITPICK, each with `file:line` and a concrete fix. If the change is good, say so briefly and don't invent problems.
- **Model:** opus.

## The four skills

They are namespaced when installed: `/studio:new-project`, `/studio:evaluate`, `/studio:spec`, `/studio:ship`. Keep each SKILL.md under ~500 lines, and put long reference material in a `references/` folder next to it.

### /new-project
- **Trigger:** the user is starting a new app or project, or the folder has no CLAUDE.md.
- **Steps:**
  1. Interview the user, one question at a time: what the app is, who it's for, the one core thing users do in it, platform (web, mobile, or both), and preferred stack (or ask Claude to recommend one, favoring popular, well-documented tools).
  2. From `templates/`, create:
     - `CLAUDE.md`, filled in and under 200 lines, covering what the app is, the stack, commands, conventions, and the workflow below.
     - `studio.config`, holding the project's format, lint, and test commands, which the hooks read.
     - `docs/product/vision.md`, drafted from the interview.
     - `docs/product/mvp.md`, with an explicit "NOT in the MVP" section.
     - empty `docs/research/`, `docs/specs/`, and `docs/decisions/` folders, each with a short README explaining what goes there.
     - `docs/decisions/0001-stack.md`, recording the stack choice and why.
  3. `git init` if the folder isn't already a repo.
  4. Offer to run `/studio:evaluate` on the idea next.
- **Mark as user-invoked only** (`disable-model-invocation: true`), since it creates files.

### /evaluate
- **Trigger:** the user has an idea, feature, or business opportunity to assess.
- **Steps:**
  1. Send the researcher to find competitors, pricing, and common complaints in competitor reviews.
  2. Send the skeptic to red-team the idea, using the research.
  3. Produce a scorecard covering problem severity, who pays and how much, competition, the user's unfair advantage, biggest risks, and a verdict (pursue, reshape, or drop).
  4. **Always end with the cheapest real-world test** (e.g. a landing page with a waitlist, or five user conversations). Agents can't validate demand; only real people can.
  5. Save the result to `docs/research/<idea-slug>-evaluation.md`.

### /spec
- **Trigger:** the user wants to build a feature.
- **Steps:**
  1. Clarify the feature with the user.
  2. Write `docs/specs/<feature-slug>.md` containing: the user story, the **vertical slice** (UI, logic, data, and tests, end to end), acceptance criteria as a checkbox list, non-goals, and open questions.
  3. Optionally have the skeptic check the scope.
  4. Keep specs small. If a spec has more than ~7 acceptance criteria, propose splitting it.
- **Output:** the spec file, plus a short implementation plan for the main session to confirm before coding.

### /ship
- **Trigger:** a feature slice is implemented and the user wants to finish it.
- **Steps:**
  1. Run the project's test command (from `studio.config`).
  2. Run the verifier against the spec's acceptance criteria.
  3. For UI changes, run the designer.
  4. Run the reviewer.
  5. Summarize all findings. Fix every BLOCKING item, then re-run the relevant check.
  6. Tick off the spec's acceptance criteria, write a commit message, and offer to open a PR.
- **Mark as user-invoked only** (`disable-model-invocation: true`), since it commits.

## Hooks (in `hooks/hooks.json`)

1. **Post-edit check (`PostToolUse` on `Write|Edit`):** runs `scripts/post-edit-check.sh`, which reads the format and lint commands from the project's `studio.config` and runs them on the edited file. If there's no `studio.config`, it exits quietly. Output feeds back to Claude so it can fix issues.
2. **Protected files (`PreToolUse` on `Write|Edit`):** runs `scripts/guard-protected-files.sh`, which blocks edits to `.env*`, files matching `*secret*` or `*.pem`, and lockfiles unless the user explicitly asked.
3. **Verifier writes only tests:** block the verifier from editing non-test files (test patterns such as `*.test.*`, `*.spec.*`, `tests/`, `__tests__/`, configurable in `studio.config`). Apply the same pattern to restrict the designer to `prototypes/`. **First, check the current hooks docs for how a hook can tell which subagent made a tool call.** If hooks can't distinguish subagents, tell the user, enforce it through the agent's instructions instead, and rely on the reviewer to catch violations.

Use `${CLAUDE_PLUGIN_ROOT}` to reference the scripts from `hooks.json`. Make the scripts portable (bash, no unusual dependencies) and executable.

## MCP (in `.mcp.json`)

- **Browser automation** (e.g. Playwright MCP) so the designer and verifier can see and click the running app.
- **GitHub (optional)** for PRs in `/ship`. Leave it commented out or documented if it needs a token, and never hard-code credentials.

## Build order (test each phase before starting the next)

**Phase 1 — skeleton plus one agent.**
Create `marketplace.json`, `plugin.json`, and the reviewer agent. Run `claude plugin validate .`.
*Done when:* `claude --plugin-dir ./plugins/studio` loads, and asking it to review a small sample diff uses the reviewer, which can't edit files.

**Phase 2 — the remaining agents.**
Add the researcher, skeptic, designer, and verifier.
*Done when:* each agent is triggered by a realistic prompt and stays within its tool limits.

**Phase 3 — /new-project and templates.**
*Done when:* running it in an empty folder produces a correct CLAUDE.md, `studio.config`, and `docs/` tree from a sample interview.

**Phase 4 — hooks.**
*Done when:* in a scaffolded test project, editing a file triggers the format and lint commands, editing `.env` is blocked, and the verifier's test-only restriction works (or its limitation is documented).

**Phase 5 — /evaluate, /spec, /ship.**
*Done when:* one sample feature goes through the full loop in a test project: evaluate → spec → implement → ship.

**Phase 6 — publish.**
Write the README, push to GitHub, and confirm that a fresh install works via `/plugin marketplace add hazyy00/kaffehaus` and `/plugin install studio@kaffehaus`.

## Later (not now)

- `/brainstorm` for divergent idea generation, saved to files.
- `/launch` checklist: deploy, analytics, error tracking, and app store requirements.
- A security reviewer agent, if an app handles auth, payments, or personal data.
- A code intelligence (LSP) plugin for the main stack.
- Dynamic workflows for codebase-wide audits or large refactors.

## How to work on this plan

- Start in plan mode. Propose how you'll build Phase 1 and wait for approval before writing files.
- Before writing any frontmatter, hook config, or manifest, check the current Claude Code docs (code.claude.com/docs) for field names. Don't rely on memory.
- Work one phase at a time, and stop at each phase's "done when" for the user to check.
- If anything in this plan conflicts with the current docs, say so and propose an alternative rather than forcing it.
