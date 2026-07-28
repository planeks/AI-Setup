---
name: run-tests
description: Runs backend (pytest) or frontend (Vitest) tests through docker compose. Use when the user asks to run tests, verify tests pass, or after changing Python or JavaScript code in this project.
---

# Run tests

All commands run from the repo root. Images must be built once: `docker compose -f compose.dev.yml build`.

## Backend (pytest + pytest-django)

Full suite in a one-off container:

```bash
docker compose -f compose.dev.yml run --rm django test
```

The `test` entrypoint command sets `DJANGO_SETTINGS_MODULE=config.settings.test` and runs plain `pytest`. It ignores extra arguments, so it always runs the whole suite.

To run a single file or test, set the settings module yourself:

```bash
docker compose -f compose.dev.yml run --rm django bash -c \
  "DJANGO_SETTINGS_MODULE=config.settings.test poetry run pytest accounts/tests/test_models.py -k test_name"
```

Paths are relative to `/opt/project/src` in the container, which is the host `src/` directory.

Postgres is started automatically as a dependency of the `django` service.

## Frontend (Vitest)

With the `frontend` service running (`docker compose -f compose.dev.yml up -d frontend`):

```bash
docker compose -f compose.dev.yml exec frontend npm test
```

Or in a one-off container:

```bash
docker compose -f compose.dev.yml run --rm frontend npm test
```

Single file: `npm test -- src/path/to/File.test.jsx`. Watch mode: `npm run test:watch`.

## CI parity

CI runs `docker compose -f compose.dev.yml run --rm django test` for the backend and `npm test` plus `npm run build` for the frontend. Match these before pushing.
