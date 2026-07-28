# CLAUDE.md — Django (PLANEKS)

> Layered on top of [`CLAUDE_base.md`](./CLAUDE_base.md) and [`CLAUDE_python.md`](./CLAUDE_python.md).

---

## Project layout

```
project/
├── config/                       # settings, urls, wsgi/asgi
│   ├── settings/
│   │   ├── base.py
│   │   ├── dev.py
│   │   ├── prod.py
│   │   └── test.py
│   ├── urls.py                   # root URL conf — mounts SSR + api/v1/*
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   └── <app_name>/
│       ├── __init__.py
│       ├── apps.py
│       ├── models.py             # domain entities + invariants
│       ├── admin.py
│       ├── tasks.py              # Celery
│       ├── selectors.py          # read logic (framework-agnostic)
│       ├── services.py           # write / business logic (framework-agnostic)
│       ├── signals.py            # only if truly needed
│       │
│       ├── views.py              # server-rendered views (SSR) — optional
│       ├── urls.py               # SSR URL routes
│       ├── forms.py              # Django forms (SSR)
│       ├── templates/<app_name>/ # SSR templates
│       │
│       ├── api/                  # ── API LAYER — fully isolated from SSR ──
│       │   ├── __init__.py
│       │   ├── views.py          # or viewsets.py — DRF
│       │   ├── serializers.py
│       │   ├── urls.py           # mounted under /api/v1/<app_name>/
│       │   ├── permissions.py    # per-app permission classes
│       │   ├── filters.py        # DRF FilterSet classes
│       │   ├── pagination.py     # only if non-default
│       │   └── schemas.py        # OpenAPI overrides, if any
│       │
│       └── tests/
│           ├── __init__.py
│           ├── factories.py
│           ├── test_models.py
│           ├── test_services.py
│           ├── test_selectors.py
│           ├── test_views.py     # SSR tests
│           └── api/
│               ├── __init__.py
│               ├── test_views.py
│               └── test_serializers.py
├── manage.py
└── requirements/
```

- One Django app per bounded context. Keep apps small and focused.
- Business logic lives in `services.py` / `selectors.py`, **not** in views or models. Models hold data + invariants only.
- **Never mix API code with SSR code in the same module.** The `api/` subpackage is the only place DRF (`serializers`, `viewsets`, DRF `permissions`) lives.

## API vs SSR isolation (mandatory)

Each app has **two distinct presentation surfaces**, kept in separate modules so a change to one never silently affects the other:

| Concern              | API layer                              | SSR layer                       |
|----------------------|----------------------------------------|---------------------------------|
| Location             | `apps/<app>/api/`                      | `apps/<app>/` (top-level)       |
| Routing              | `apps/<app>/api/urls.py` → `/api/v1/<app>/...` | `apps/<app>/urls.py` → `/<app>/...` |
| Views                | DRF `APIView` / `ViewSet`              | Django `View` / `TemplateView`  |
| Input shape          | JSON via DRF serializers               | HTML forms via Django forms     |
| Auth                 | `permission_classes`, token/JWT        | `LoginRequiredMixin`, sessions  |
| Tests                | `tests/api/`                           | `tests/test_views.py`           |

### Rules

1. **Both layers call the same `services.py` / `selectors.py`.** Business logic is shared, presentation is not.
2. `api/` modules **never** import from `views.py`, `forms.py`, or `templates/`. SSR modules **never** import from `api/`.
3. DRF imports (`from rest_framework import ...`) appear **only** inside `api/`. If you see DRF in `views.py` — move it.
4. `serializers.py` lives in `api/` only. Don't reuse serializers as a generic "object → dict" tool elsewhere — use plain functions or dataclasses.
5. If an app is API-only (no SSR), keep the top-level `views.py` / `urls.py` / `templates/` absent. Don't create empty placeholders.
6. If an app is SSR-only, the `api/` directory simply doesn't exist for that app.
7. Root `config/urls.py` mounts each app's URLs twice (if both surfaces exist):
   ```python
   # config/urls.py
   urlpatterns = [
       path("admin/", admin.site.urls),
       # SSR
       path("users/", include("apps.users.urls", namespace="users")),
       # API
       path("api/v1/users/", include("apps.users.api.urls", namespace="users-api")),
   ]
   ```
8. Namespacing: SSR namespace = app name (`users`), API namespace = `<app>-api` (`users-api`). Reverse names stay distinct.

### When adding a new endpoint

- API endpoint → create/extend `apps/<app>/api/views.py` + `apps/<app>/api/serializers.py` + register in `apps/<app>/api/urls.py`.
- SSR page → create/extend `apps/<app>/views.py` + template + register in `apps/<app>/urls.py`.
- New business rule → goes into `services.py` / `selectors.py`, then **both** layers can use it.

## Settings

- Split settings: `base.py` + per-env overrides. Choose env via `DJANGO_SETTINGS_MODULE`.
- All secrets and env-specific values via env vars. Use `django-environ` or `pydantic-settings`.
- `DEBUG = False` in production. `ALLOWED_HOSTS` set explicitly.
- `SECRET_KEY` — env var, never committed.

## Models

- One model = one entity. Use abstract base models for shared fields (`created_at`, `updated_at`).
- Add `__str__` and `Meta.ordering` to every model.
- Choices: use `TextChoices` / `IntegerChoices`.
- Indexes: declare in `Meta.indexes` for any field used in lookups/joins.
- Constraints (uniqueness, checks): use `Meta.constraints` over signals.

## Migrations

- One migration per logical change. Review autogenerated migrations before committing.
- Never edit a migration after it's been applied to a shared environment — write a new one.
- Test migrations on a copy of prod data before deploying.
- For large tables: avoid blocking schema changes during business hours; use `RunPython` with `atomic = False` if needed.

## Querysets & ORM

- **Avoid N+1.** Use `select_related` (FK) and `prefetch_related` (reverse FK / M2M).
- Use `.only()` / `.defer()` for wide tables when you need only a few fields.
- Heavy aggregations → `.annotate()` + `.aggregate()`; don't compute in Python.
- For bulk ops: `bulk_create`, `bulk_update`, `update()`, `delete()` — but mind that they bypass signals and `save()`.
- Wrap multi-step writes in `transaction.atomic()`.

## Views

- Class-based views (CBV) for CRUD; function-based for one-off endpoints.
- For APIs use **Django REST Framework** (DRF). For GraphQL use **Strawberry** or **Graphene** (project's choice).
- Keep views thin — delegate to services/selectors.

### DRF specifics (lives only under `api/`)

- All DRF code (`ViewSet`, `Serializer`, `permission_classes`, `FilterSet`) goes in `apps/<app>/api/`.
- `ViewSet` + `Router` for resourceful APIs. Register the router in `apps/<app>/api/urls.py`.
- Serializers validate input and shape output. Don't put business logic in serializers — call `services.py` from `create`/`update`.
- Permissions: per-view `permission_classes` or DRF global default. Never rely on UI to enforce access.
- Pagination: default class in settings. Don't return unpaginated lists.
- Throttling for public/auth-sensitive endpoints.

## URLs

- **SSR routes:** `apps/<app>/urls.py` with `app_name = "<app>"`, mounted at `/<app>/`.
- **API routes:** `apps/<app>/api/urls.py` with `app_name = "<app>-api"`, mounted at `/api/v1/<app>/`.
- Use `path()` with named patterns. Avoid regex unless necessary.
- API is **always** versioned: `/api/v1/...`. Bump the version, never break v1 silently.

## Forms & templates

- Server-rendered? Use Django forms with explicit field declarations. Avoid `Meta: fields = "__all__"` for security.
- Always escape user input — `{{ var }}` auto-escapes; use `|safe` only when you've verified the source.
- CSRF protection on by default — keep it on. Use `{% csrf_token %}` in forms.

## Admin

- Register models with custom `ModelAdmin`. Limit `list_display`, add `search_fields`, `list_filter`.
- For sensitive models: restrict `has_*_permission` instead of leaving defaults.
- Randomize the admin URL via an env var (e.g. `ADMIN_URL`); don't hardcode `admin/` in `urls.py` for production builds.

## Auth

- Custom `User` model from day one — even if you don't need it yet. Extend `AbstractBaseUser` / `AbstractUser`.
- Permissions: prefer object-level via `django-guardian` if RBAC isn't enough.
- Sessions for SSR; tokens (DRF token, JWT via `djangorestframework-simplejwt`) for APIs.

## Celery (async tasks)

- Place tasks in `<app>/tasks.py`. Decorate with `@shared_task` for app-independence.
- Tasks must be idempotent — they will retry.
- Pass IDs, not ORM objects (objects can be stale or unpickleable). Refetch inside the task.
- Set explicit `time_limit` and `soft_time_limit`. Configure retries with backoff.
- Use **Redis** as broker by default; **RabbitMQ** when ordering/durability requires it.

## Caching

- Use `django.core.cache` with **Redis** backend.
- Cache invalidation: prefer short TTLs + explicit invalidation on writes. Avoid manual key juggling.
- Don't cache user-specific data without including the user in the key.

## Static & media files

- `collectstatic` in deploy. Serve with **WhiteNoise** for small apps, **Nginx/Caddy** + cloud storage (S3) for larger ones.
- User uploads (media) → cloud storage in production (`django-storages` + S3). Never local disk in containers.

## Testing

- **pytest-django** preferred. Use `@pytest.fixture` + factories (`factory_boy`) over Django's `TestCase` when possible.
- Factories per model in `tests/factories.py`.
- `pytest.mark.django_db` for DB access. Use `transactional_db` only when needed.
- Don't hit external services — mock with `responses` / `respx`.
- Test what users do: views/APIs end-to-end; unit-test services/selectors directly.

## Security

- `django-axes` or similar for brute-force protection.
- `SECURE_*` settings in production: `SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`, `SECURE_HSTS_SECONDS`.
- Run `python manage.py check --deploy` before going to prod.

## Performance

- `django-debug-toolbar` in dev to catch slow queries and N+1.
- `django-silk` for ad-hoc production profiling (gate behind auth).
- Database connection pooling: `CONN_MAX_AGE` or `pgbouncer`.

---

## Anti-patterns

- **Mixing API and SSR code in the same module** — DRF serializers in `views.py`, or template rendering in `api/views.py`. Move them to their correct layer.
- Importing `apps.<app>.api.*` from outside the `api/` package (other than root `urls.py`). The API layer is a presentation detail, not a service.
- Sharing DRF serializers as a generic "model → dict" helper across the codebase — use plain functions or dataclasses for that.
- Fat models with business logic that touches multiple apps.
- Signal handlers that hide write paths — explicit service calls are easier to reason about.
- `objects.all()` in templates / serializers — always paginate or filter.
- Putting Celery tasks inline (`task.delay()`) inside a transaction — they may fire before the commit; use `transaction.on_commit(lambda: task.delay(...))`.
- Catching `Exception` in views to "make it work" — fix the root cause.
