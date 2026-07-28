# AGENTS.md

Instructions for AI coding agents working in this repository (PLANEKS
django-react-docker-boilerplate). Nested `AGENTS.md` files add rules for their subtree —
`src/` for Django/Python, `src/frontend/` for React. The closest file wins.

## The one rule that breaks everything else

**Everything runs inside Docker.** Never `pip install`, `npm install`, or `python manage.py`
on the host — the host has no venv and can't reach Postgres/Redis.

**There is no `docker-compose.yml` and no Makefile.** Every command needs an explicit
`-f compose.dev.yml`; omitting it can silently target the prod stack.

```bash
docker compose -f compose.dev.yml build            # after Dockerfile/pyproject/package.json changes
docker compose -f compose.dev.yml up -d
docker compose -f compose.dev.yml logs -f django   # or frontend / celeryworker / celerybeat
docker compose -f compose.dev.yml down -v          # DESTRUCTIVE (wipes the DB) — ask first
```

## The `django` entrypoint

`docker/django/entrypoint` dispatches on its first argument and sets the venv, user (`gosu
appuser`) and settings module for you. **Prefer these verbs over raw `python manage.py`:**

| Verb | Does |
|---|---|
| `manage <cmd>` | `python manage.py <cmd>` |
| `test` | exports `DJANGO_SETTINGS_MODULE=config.settings.test`, runs `pytest` |
| `add <pkg>` | `poetry add` |
| `shell` | `manage.py shell` |
| `dev` / `prod` | migrate + runserver / migrate + collectstatic + gunicorn |
| `celery` / `celery-dev` / `bash` / `python` | as named |

```bash
docker compose -f compose.dev.yml run --rm django manage makemigrations
docker compose -f compose.dev.yml run --rm django test
docker compose -f compose.dev.yml exec frontend npm run lint
```

`run --rm` for one-offs, `exec` when the stack is already up — but note the difference:
**`exec` bypasses the entrypoint and runs as `root`** (the image's final `USER`). The venv is on
`PATH`, so `exec django ruff check .` works fine. Anything that *writes* into the bind-mounted
`./src` — `manage makemigrations`, `ruff format` — should go through `run --rm django <verb>`
instead, or it leaves root-owned files on the host.

## Services

`django` :8000 · `frontend` (Vite) :5173 · `flower` :5555 · `mailhog` :8025 · `mkdocs` :8050 ·
`celeryworker` · `celerybeat` · `redis` · `postgres` · `caddy` :80/443 (profile `dev`, off by
default). Full definitions: `compose.dev.yml` / `compose.prod.yml`.

`./src` is bind-mounted to `/opt/project/src` — **edit on the host**, never inside the container.

## Layout

```
src/config/     settings/{base,dev,prod,test}.py, urls.py, celery.py
src/accounts/   custom User (AUTH_USER_MODEL) — copy this app's shape for new apps
src/core/       IndexView, middleware, management commands
src/frontend/   Django app AND the React/Vite project (see its own AGENTS.md)
docker/ scripts/ ansible/ docs/
```

Routes: `/` SPA shell · `/superadmin/` · `/api/token/` + `/api/token/refresh/` (JWT) ·
`/api/schema/` · `/api/docs/` · `/api/redoc/` · `/__debug__/` (dev only).

## Configuration

`dev.env` and `prod.env` are committed **templates**; the real file is `.env` (gitignored).
Never put a secret in the templates. New env var → add a placeholder to **both** templates,
read it via `python-decouple` in `src/config/settings/base.py` with a safe default, document
it in `docs/`.

A fresh clone needs `cp dev.env .env`, a fresh `SECRET_KEY`, `COMPOSE_PROJECT_NAME`, an
`/etc/hosts` entry matching `SITE_URL`, and the `NEWPROJECTNAME` placeholder replaced repo-wide.

## Quality gates

Configs are the source of truth — read them rather than trusting a summary here:
`src/pyproject.toml` (Ruff), `src/frontend/eslint.config.js`, `src/frontend/.prettierrc`,
`.pre-commit-config.yaml`, `.github/workflows/ci.yml`.

CI on PRs to `develop`/`staging`/`main`: migration-conflict check, `lint-backend`,
`lint-frontend`, `test-backend`, `test-frontend` (the two test jobs are skipped for PRs
targeting `develop`). Don't bypass CI or pre-commit — fix the cause. No `--no-verify`.

> Known drift: `.pre-commit-config.yaml` pins ruff `v0.15.1`, `pyproject.toml` pins `^0.6.7`.
> If the hook and the container disagree on formatting, that's why — report it, don't `# noqa` it.

## Deploys

`develop` → dev (no CI gate) · `staging` → CI then prod compose · `main` → manual approval + CI.
All via `scripts/deploy.sh` over SSH from CI — **never run a deploy from a laptop**.
See `docs/deployment_automated.md`.

## Conventions

- **English only** — code, comments, commits, branches, docs. No exceptions.
- Branches and commits follow `CONTRIBUTING.md`: prefixes `feature/` `bugfix/` `hotfix/`
  `task/`, lowercase and hyphenated; [Conventional Commits](https://www.conventionalcommits.org/).
- Don't push, merge, or deploy on the user's behalf.
- Docs change in the **same** PR as the code that made them stale.
- Tests accompany every change. Update `README.md` / `docs/` when setup or public API moves.
- Never commit `.env`, secrets, build artifacts, or commented-out code.

## Skills

Task-specific procedures live as skills in `.agents/skills/` (Claude Code loads them from the
`.claude/skills` symlink; Codex and others read `.agents/skills/` directly). **Read the matching
skill before the work** — e.g. `django-backend`, `react-frontend`, `api-contract-change`,
`verify-change`, `django-migrations`, `docker-services`, `lint-fix`, `run-tests`. See
`.agents/skills/README.md` for the full index.

## Full standards

The complete PLANEKS standards are vendored in `.claude/` — `CLAUDE_base.md`,
`CLAUDE_python.md`, `CLAUDE_django.md`, `CLAUDE_react.md`, `CLAUDE_architecture.md`.
They cover error handling, docstrings, API design, caching, resilience and security in depth.
**Read the relevant one before a design decision** (new app, new endpoint, caching, background
work); the summaries in these `AGENTS.md` files are deliberately partial.

Where a template and this repo disagree, **this repo wins** — the deviations are listed in the
nested `AGENTS.md` files.
