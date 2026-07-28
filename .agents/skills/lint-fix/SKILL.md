---
name: lint-fix
description: Runs linters and formatters for backend (ruff) and frontend (ESLint, Prettier) through docker compose, with autofix. Use when the user asks to lint, format, fix style issues, or before a commit when CI lint jobs must pass.
---

# Lint and format

Run from the repo root with the dev stack up. If the stack is down, replace `exec` with `run --rm`.

## Backend (ruff, config in `src/pyproject.toml`)

```bash
docker compose -f compose.dev.yml exec django ruff check --fix .
docker compose -f compose.dev.yml exec django ruff format .
```

Check-only, what CI runs:

```bash
docker compose -f compose.dev.yml exec django ruff check .
docker compose -f compose.dev.yml exec django ruff format --check .
```

## Frontend (ESLint + Prettier)

```bash
docker compose -f compose.dev.yml exec frontend npm run lint:fix
docker compose -f compose.dev.yml exec frontend npm run format
```

Check-only, what CI runs:

```bash
docker compose -f compose.dev.yml exec frontend npm run lint
docker compose -f compose.dev.yml exec frontend npm run format:check
```

## Everything at once

Pre-commit hooks bundle ruff, ESLint, and Prettier (`.pre-commit-config.yaml`), run on the host:

```bash
pre-commit run --all-files
```

Fix real errors by editing code. Only suppress a rule (`# noqa`, `eslint-disable`) when the rule itself is wrong for that line, and say why in the same line.
