# CLAUDE.md

Guidance for Claude Code in this repository.

The project's own rules live in `AGENTS.md` files, so every agent (Codex, Cursor, Copilot,
Gemini CLI, Claude Code) reads the same source. Claude Code doesn't pick up nested `AGENTS.md`
by directory proximity the way Codex does, so all three are imported here explicitly:

@AGENTS.md
@src/AGENTS.md
@src/frontend/AGENTS.md

Those files are hand-maintained — edit them directly, and keep them short. They carry only what
an agent can't infer from the code and configs.

## Shared PLANEKS standards

The company-wide templates are vendored in `.claude/`. They are **not** imported
into context by default — that would add ~900 lines to every request, most of it already
enforced by Ruff, ESLint, Prettier and pre-commit.

Read the relevant one when a decision warrants it:

| File | Read it before |
|---|---|
| `.claude/CLAUDE_base.md` | anything about commits, PRs, comments, docstrings, secrets |
| `.claude/CLAUDE_python.md` | error handling, logging, typing, concurrency choices |
| `.claude/CLAUDE_django.md` | adding an app, endpoint, model, migration, Celery task |
| `.claude/CLAUDE_react.md` | state management, data fetching, forms, accessibility |
| `.claude/CLAUDE_architecture.md` | layering, API design, caching, resilience, multi-tenancy |

These are generic company-wide standards, not a description of this codebase. If a template and
an `AGENTS.md` disagree, **the `AGENTS.md` wins** — the deviations are documented there with
reasons. Two known conflicts worth naming, because following the template would be wrong here:

- `CLAUDE_django.md` prescribes `services.py` / `selectors.py`. This project has **no service
  layer** — logic lives in DRF views and model managers.
- `CLAUDE_django.md` prescribes `ViewSet` + `DefaultRouter`. This project uses **generic
  class-based views + explicit `path()`**.

`CLAUDE_react.md` is TypeScript-first; this frontend is plain JSX. See `src/frontend/AGENTS.md`.
