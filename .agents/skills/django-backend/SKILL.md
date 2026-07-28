---
name: django-backend
description: Conventions for backend changes in this repo — Django 5.1 / DRF models, migrations, serializers, views, permissions, Celery tasks, PostgreSQL, and backend tests. Use when editing anything under src/ Python (accounts, core, config), especially the <app>/api/ packages. Not for frontend or pure API-contract coordination (see react-frontend, api-contract-change).
---

# Django backend

Stack: Poetry, Python 3.12, Django 5.1, DRF 3.15, drf-spectacular, SimpleJWT, Celery 5.3 (+ redbeat) on Redis, PostgreSQL. Ruff is the only linter/formatter. Everything runs in Docker via `compose.dev.yml`.

## Where code lives

- Domain apps live under `src/`. Today `accounts` is the only real domain app; `core` holds middleware/management commands; `config` is the project package (settings, celery, urls).
- API code sits in a per-app `api/` subpackage: `src/accounts/api/{views,serializers,permissions,router,tests}.py`.
- URLs: each app's `api/router.py` exposes an `api_urlpatterns` list, included from `<app>/urls.py` under a namespace (e.g. `accounts_api`). Project routes are in `src/config/urls.py`.

## Layer responsibilities

This project does **not** use a service layer or selectors. Do not introduce `services.py` / `selectors.py` — follow the existing pattern:

- **Model + manager** (`models.py`) — persistence and domain helpers. Creation/normalization logic lives on the manager (see `UserManager._create_user` in `src/accounts/models.py`). Add row-level domain methods to the model.
- **Serializer** (`api/serializers.py`) — input validation and output shape. `ModelSerializer` for CRUD, plain `Serializer` for actions (see `ChangePasswordSerializer`). Validation goes in `validate()` / `validate_<field>()`. `create()`/`update()` may delegate to the manager.
- **View** (`api/views.py`) — request orchestration. DRF **generic class-based views** (`CreateAPIView`, `RetrieveUpdateAPIView`) and `APIView`; wired with explicit `path()` in `router.py`. **No ViewSets, no DefaultRouter.** A view may compose several steps (validate, persist, dispatch a Celery task, mint JWT) — see `RegisterView.create`.
- **Task** (`tasks.py`) — `@shared_task` functions, dispatched with `.delay(...)`. Keep them small and idempotent; look up objects by id inside the task, tolerate missing rows (see `send_email`).

## Rules

- **Permissions**: default auth is JWT (SimpleJWT). DRF has **no default permission configured** (`REST_FRAMEWORK` in `config/settings/base.py` sets no `DEFAULT_PERMISSION_CLASSES`), so it falls back to `AllowAny` — a view without an explicit `permission_classes` is **public**. Always set it. There is **no multi-tenancy / object-level ownership layer** — if a view returns per-user data, filter the queryset by `request.user` yourself. (Note: `accounts/api/permissions.py` is a dead stub importing a non-existent `oxygen` package — do not import from it.)
- **OpenAPI**: annotate every view with drf-spectacular `@extend_schema` / `@extend_schema_view` so the generated schema stays accurate. See `api-contract-change` when a request/response shape changes.
- **Transactions, `select_for_update`, N+1, migrations**: see [references/backend-conventions.md](references/backend-conventions.md). None of these patterns exist in the repo yet — the reference gives the rules to follow when you add write-heavy or list endpoints.

## Testing

- Tests are Django `TestCase` / DRF `APITestCase` classes, run by pytest-django. No `conftest.py`, no factory_boy — build objects directly (`User.objects.create_user(...)`).
- Model/unit tests: `src/accounts/tests/test_*.py`. API tests: `src/<app>/api/tests.py` — use `reverse("accounts_api:<name>")`, `self.client` and `force_authenticate`.
- Add a test with every behavior change. New endpoints get an `APITestCase` covering auth required, happy path, and validation errors.

## Verify

Run the narrowest sufficient check (see `verify-change`). Containers must be up (`docker compose -f compose.dev.yml up -d`).

```bash
docker compose -f compose.dev.yml exec django ruff check .
docker compose -f compose.dev.yml exec django ruff format --check .
docker compose -f compose.dev.yml run --rm django test
```

After model changes: `docker compose -f compose.dev.yml exec django python manage.py makemigrations` then `migrate`, and commit the migration.
