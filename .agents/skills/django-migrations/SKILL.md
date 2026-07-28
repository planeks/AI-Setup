---
name: django-migrations
description: Creates, applies, and checks Django migrations through docker compose, and resolves migration number conflicts. Use after changing Django models, when the user asks for makemigrations or migrate, or when CI fails on the migration conflict check.
---

# Django migrations

All commands run from the repo root against the dev stack. If the stack is down, replace `exec django python manage.py` with `run --rm django manage`.

## Create and apply

```bash
docker compose -f compose.dev.yml exec django python manage.py makemigrations
docker compose -f compose.dev.yml exec django python manage.py migrate
```

The dev entrypoint runs `migrate` on every `django` service start, so a restart also applies pending migrations.

## Check without changing anything

```bash
# Model changes with no migration yet? Exits non-zero if one is missing.
docker compose -f compose.dev.yml exec django python manage.py makemigrations --check --dry-run

# Unapplied migrations? Exits non-zero if any are pending.
docker compose -f compose.dev.yml exec django python manage.py migrate --check
```

Inspect the SQL a migration will run:

```bash
docker compose -f compose.dev.yml exec django python manage.py sqlmigrate accounts 0002
```

## Migration conflicts

The CI job `check_migration_conflicts` fails a PR when it adds a migration whose app and number prefix (for example `accounts/0003`) already exists on the base branch.

To fix: rebase on the base branch, delete your own new migration file (never one that is already on the base branch), and regenerate it with `makemigrations` so it gets the next free number.

## Rules

- Never edit or delete a migration that exists on the base branch. Others may have applied it.
- Keep the migration count per PR as low as possible. If repeated `makemigrations` runs piled up several files, delete them and regenerate as one before the PR merges.
- Data migrations (`RunPython`, `RunSQL`) always go in their own file, never mixed with schema changes. Schema first, then the data migration on top.
- Review the generated file before committing it.
- Tests use `config.settings.test` and build their own database; no need to migrate the dev database for tests.
