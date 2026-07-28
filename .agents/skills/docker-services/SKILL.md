---
name: docker-services
description: Reference for this project's docker compose dev stack. Use when starting or stopping services, checking logs or status, opening a shell, running manage.py commands, adding packages, or asking which service owns which port.
---

# Docker dev stack

Everything goes through `compose.dev.yml` from the repo root. `compose.prod.yml` is for servers; never run it locally.

## Services

| Service | Port | What it is |
|---|---|---|
| django | 8000 | Django dev server (auto-migrates on start) |
| frontend | 5173 | Vite dev server (React) |
| celeryworker | — | Celery worker, hot reload |
| celerybeat | — | Celery beat scheduler, hot reload |
| flower | 5555 | Celery monitoring UI |
| postgres | — | Database (data in `./data/dev_postgres`) |
| redis | — | Cache + Celery broker |
| mailhog | 8025 | Catches outgoing email, web UI |
| mkdocs | 8050 | Project docs server |
| caddy | 80/443 | Reverse proxy, optional (`--profile dev`) |

## Common operations

```bash
docker compose -f compose.dev.yml up -d           # start stack
docker compose -f compose.dev.yml ps              # status
docker compose -f compose.dev.yml logs -f django  # follow logs
docker compose -f compose.dev.yml stop            # stop, keep data
```

Do not use `down -v`. It deletes volumes, including the database.

## Running things in containers

The django image has an entrypoint with subcommands (`docker/django/entrypoint`):

```bash
docker compose -f compose.dev.yml exec django bash               # shell in running container
docker compose -f compose.dev.yml run --rm django bash           # one-off shell
docker compose -f compose.dev.yml run --rm django manage <cmd>   # any manage.py command
docker compose -f compose.dev.yml run --rm django shell          # Django Python shell
docker compose -f compose.dev.yml run --rm django add <package>  # poetry add + lock update
docker compose -f compose.dev.yml run --rm django test           # pytest suite
```

Frontend has no custom entrypoint; run npm directly:

```bash
docker compose -f compose.dev.yml exec frontend npm run <script>
```
