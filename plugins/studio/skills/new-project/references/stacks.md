# Recommended stacks

Read this when the user asks you to recommend a stack. These favor popular, well-documented tools with large communities, so answers and examples are easy to find.

Last reviewed 2026-11-03. Tools, versions, and flags change: check each tool's current docs before scaffolding.

## How to choose

| The user wants | Recommend |
|---|---|
| A web app | **A. Next.js** |
| A mobile app (iOS and Android) | **B. Expo** |
| Web and mobile from one codebase | **C. Expo for web and mobile** |
| An API or backend only, data or AI work, or they prefer Python | **D. FastAPI** |

Give a 2–3 sentence reason tied to what they told you, name the runner-up and why it lost, and ask them to confirm.

Don't pick a database, auth provider, or hosting now. Decide each one in the first spec that needs it, and record it in `docs/decisions/`.

## A. Next.js (web)

- **Stack:** Next.js (App Router), TypeScript, Tailwind CSS. Vitest for unit tests, Playwright for end-to-end tests.
- **Scaffold tool:** `create-next-app`, then add Prettier and Vitest as dev dependencies.
- **Install:** `npm install`
- **Dev server:** `npm run dev` (http://localhost:3000)
- **studio.config:**
  - `format = npx --no -- prettier --write {file}`
  - `format_files = *.ts *.tsx *.js *.jsx *.mjs *.css *.json`
  - `lint = npx --no -- eslint {file}`
  - `lint_files = *.ts *.tsx *.js *.jsx *.mjs`
  - `test = npx --no -- vitest run`
  - `test_files = *.test.* *.spec.* __tests__/* tests/* e2e/*`
- **Conventions:**
  - TypeScript in strict mode. Avoid `any`.
  - Server components by default. Add `"use client"` only to components that need the browser.
  - Style with Tailwind classes, not separate CSS files.

## B. Expo (mobile)

- **Stack:** Expo (React Native) with Expo Router, TypeScript. Jest with `jest-expo` for tests.
- **Scaffold tool:** `create-expo-app`, then add Prettier and Jest.
- **Install:** `npm install`
- **Dev server:** `npx expo start`. Run `npx expo start --web` to check screens in a browser, which is what the designer agent uses.
- **studio.config:**
  - `format = npx --no -- prettier --write {file}`
  - `format_files = *.ts *.tsx *.js *.jsx *.json`
  - `lint = npx --no -- eslint {file}`
  - `lint_files = *.ts *.tsx *.js *.jsx`
  - `test = npx --no -- jest`
  - `test_files = *.test.* *.spec.* __tests__/* tests/*`
- **Conventions:**
  - TypeScript in strict mode. Avoid `any`.
  - Screens live in `app/` and follow Expo Router's file-based routing.
  - Check each feature on a phone or simulator as well as on the web.

## C. Expo for web and mobile

Same as **B**, and the web build comes from the same code. The trade-off: public marketing pages and SEO are weaker than with Next.js. If a public website matters, add a separate Next.js site later and record that as a decision.

## D. FastAPI (Python API or backend)

- **Stack:** Python, FastAPI, Pydantic. `uv` for dependencies, Ruff for formatting and linting, pytest for tests.
- **Scaffold tool:** `uv init`, then `uv add fastapi --extra standard` and `uv add --dev ruff pytest`.
- **Install:** `uv sync`
- **Dev server:** `uv run fastapi dev` (http://127.0.0.1:8000). Add the app's path if it isn't `main.py`.
- **studio.config:**
  - `format = uv run ruff format {file}`
  - `format_files = *.py`
  - `lint = uv run ruff check {file}`
  - `lint_files = *.py`
  - `test = uv run pytest`
  - `test_files = test_*.py *_test.py conftest.py tests/*`
- **Conventions:**
  - Type hints on every function. Use Pydantic models for request and response bodies.
  - Keep route handlers thin. Put the logic in plain functions that are easy to test.

## The user's own stack

If the user names a stack that isn't listed here, use that stack's standard formatter, linter, and test runner. If you aren't sure what those are, ask, and leave the value empty rather than guess. Confirm the commands with the user before you write `studio.config`.
