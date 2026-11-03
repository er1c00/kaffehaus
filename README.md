# kaffehaus

A Claude Code plugin marketplace with one plugin, **studio**. It gives every project the same workflow from idea to shipped app:

**validate → define → design → build in slices → verify → review → ship**

The plugin works with any stack. Each project keeps its own format, lint, and test commands in a `studio.config` file, which `/studio:new-project` creates.

## Install

### Requirements

- **Claude Code.** Tested on v2.1.309.
- **Git and bash.** The hooks are bash scripts. On Windows, install [Git for Windows](https://gitforwindows.org/), which includes Git Bash.
- **Node.js 18 or later and Google Chrome**, for the browser tools that the designer and verifier use.
- **A git name and email**, so `/studio:ship` can commit:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```

### Add the marketplace and install the plugin

In a Claude Code session:

```
/plugin marketplace add hazyy00/kaffehaus
/plugin install studio@kaffehaus
```

Or from your shell:

```bash
claude plugin marketplace add hazyy00/kaffehaus
claude plugin install studio@kaffehaus
```

Start a new session, or run `/reload-plugins`, to load it.

### Updates

`plugin.json` doesn't pin a version, so every commit pushed to this repository is a new version. Claude Code doesn't auto-update third-party marketplaces by default, so do one of these:

- **Turn on auto-update:** run `/plugin`, open **Marketplaces**, choose **kaffehaus**, and select **Enable auto-update**.
- **Update by hand:**
  ```bash
  claude plugin marketplace update kaffehaus
  claude plugin update studio@kaffehaus
  ```

Then run `/reload-plugins` or start a new session.

## Use

### 1. Set up a project

In an empty folder, run `/studio:new-project`. It interviews you one question at a time (the app, who it's for, the core action, platform, and stack), shows a summary to confirm, and then creates:

| File | What it holds |
|---|---|
| `CLAUDE.md` | What the app is, the stack, commands, conventions, and the workflow |
| `studio.config` | The format, lint, and test commands that the hooks and the verifier use |
| `docs/product/vision.md` | The problem, who it's for, and the assumptions to test |
| `docs/product/mvp.md` | What's in the first version, and an explicit "NOT in the MVP" list |
| `docs/decisions/0001-stack.md` | The stack choice and why |
| `docs/research/`, `docs/specs/`, `docs/decisions/` | Each with a README explaining what goes there |

It also runs `git init` if needed. It doesn't scaffold the app's code; the first build slice does that.

### 2. Work in slices

| Command | What it does | Saves |
|---|---|---|
| `/studio:evaluate <idea>` | The researcher finds competitors, pricing, and review complaints. The skeptic red-teams the idea. You get a scorecard, a verdict (pursue, reshape, or drop), and the cheapest real-world test. | `docs/research/<idea>-evaluation.md` |
| `/studio:spec <feature>` | Clarifies the feature, then writes a small spec: user story, vertical slice, acceptance criteria, non-goals, and open questions. Proposes a plan and waits for you to confirm it. | `docs/specs/<feature>.md` |
| *(build)* | The main session writes the code for one slice. | |
| `/studio:ship <feature>` | Runs the tests, the verifier, the designer (for UI changes), and the reviewer. Fixes every BLOCKING finding, ticks off the spec, and commits. | A commit |

Claude can start `/studio:evaluate` and `/studio:spec` on its own when they fit what you ask. Only you can start `/studio:new-project` and `/studio:ship`, because they create files and commit.

### Agents

The main session delegates to these agents automatically when the task fits. To call one directly, type `@agent-studio:<name>`.

| Agent | Model | Job | Can use |
|---|---|---|---|
| `researcher` | Sonnet | Web and market research. Returns findings with sources, and what it couldn't confirm. | Read-only tools, web search and fetch |
| `skeptic` | Opus | Red-teams ideas, MVP scope, and plans. Ends with the cheapest real-world test. | Read-only tools, web search and fetch |
| `designer` | Sonnet | Critiques the running UI in a browser at mobile and desktop widths. Makes throwaway prototypes. | Read-only tools, the browser, and writes in `prototypes/` only |
| `verifier` | Sonnet | Writes and runs tests that try to break a feature, checked against the spec. | Read-only tools, Bash, the browser, and edits test files only |
| `reviewer` | Opus | Reviews the diff against the spec in a fresh context. Reports BLOCKING, SHOULD FIX, and NITPICK findings with `file:line`. | Read-only tools, and read-only git commands |

## studio.config

One `key = value` per line. Lines starting with `#` are comments. `{file}` is replaced with the path of the file that was just edited.

```
format = npx --no -- prettier --write {file}
format_files = *.ts *.tsx *.js *.jsx *.css *.json
lint = npx --no -- eslint {file}
lint_files = *.ts *.tsx *.js *.jsx
test = npx --no -- vitest run
test_files = *.test.* *.spec.* __tests__/* tests/*
```

- A file matches a pattern if its name matches, or its path from the project root does, at any depth. `*` also matches `/`. An empty `*_files` value means every file.
- An empty `format`, `lint`, or `test` value turns that step off.
- The `--no --` in `npx --no -- <tool>` stops npx from downloading a tool that isn't installed.

## Guardrails

Hooks enforce these rules on every tool call. They don't rely on the agents following instructions.

- **After every edit**, the file's `format` and `lint` commands run. Any problems go back to Claude to fix.
- **Protected files** (`.env*`, `*secret*`, `*.pem`, and lockfiles): an edit in the main session asks you first, and agents are always blocked. `.env.example`, `.env.sample`, and `.env.template` are allowed.
- **Agent limits**: the verifier can edit test files only and can't commit, install packages, or delete files. The designer can write only in `prototypes/`. The reviewer can run only read-only commands.
- **In an empty folder** with no `CLAUDE.md`, Claude suggests `/studio:new-project` instead of setting the project up its own way.

Known limits:
- The Bash checks read a command as text, not as a shell would. They block anything they can't tell is safe, but a determined workaround could get through. The reviewer is the second line of defence.
- The protected-files guard covers Claude's Write and Edit tools, not shell commands such as `echo > .env`.

## Browser and GitHub

- **Browser:** the plugin's `.mcp.json` runs [Playwright MCP](https://github.com/microsoft/playwright-mcp), pinned to version 0.0.83. The browser runs headless, with a fresh profile each session. The first run downloads it with `npx`. It can't open `file://` URLs, so the designer needs the app served on `localhost`.
- **GitHub:** no GitHub MCP server is bundled, because it needs a personal token, and a token must never go in this repository. When the repository has a GitHub remote and the [`gh` CLI](https://cli.github.com/) is installed and signed in, `/studio:ship` offers to open a pull request with `gh pr create`. To use the GitHub MCP server instead, add it to your own Claude Code configuration. See [Claude Code MCP](https://code.claude.com/docs/en/mcp).

## Develop the plugin

```
kaffehaus/
├── .claude-plugin/marketplace.json   # the marketplace: lists studio at ./plugins/studio
├── plan.md                           # the original build plan
└── plugins/studio/
    ├── .claude-plugin/plugin.json
    ├── .mcp.json                     # Playwright MCP
    ├── agents/                       # researcher, skeptic, designer, verifier, reviewer
    ├── hooks/hooks.json
    ├── scripts/                      # the hook scripts, and lib.sh, which they share
    └── skills/                       # new-project (with templates), evaluate, spec, ship
```

- **Try local changes** without installing: `claude --plugin-dir ./plugins/studio`.
- **Validate** after every change: `claude plugin validate .` and `claude plugin validate ./plugins/studio`.
- **Agent and skill frontmatter:** `validate` doesn't check it. Avoid an unquoted `: ` inside a value, which breaks the YAML. Broken frontmatter is ignored silently, and the agent's `tools` limit goes with it.
- **Shell scripts** must keep LF line endings (`.gitattributes` handles that) and be executable. Add new ones with `git add --chmod=+x`.
- **Test projects** go in `sandbox/`, which git ignores.

## License

Copyright (c) 2026 Eric. All rights reserved. See [LICENSE](LICENSE).
