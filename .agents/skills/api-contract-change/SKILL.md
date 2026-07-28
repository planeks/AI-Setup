---
name: api-contract-change
description: Coordinate a change that alters the API contract — an endpoint, request/response shape, serializer field, permission, pagination, filtering, the OpenAPI schema, or an event/task payload — so backend producer and consumers stay in sync. Use whenever a change is observable across the DRF boundary, not for backend-internal refactors.
---

# API contract change

The contract is defined backend-first: DRF serializers/views in `src/<app>/api/`, published as an OpenAPI schema by drf-spectacular. There is **no generated client** and the frontend does not consume the API yet, so keeping the schema honest and the consumers updated is manual work.

## Workflow

1. **Identify producer and consumers.**
   - Producer: the serializer + view in `src/<app>/api/`, routed via `api/router.py`.
   - Consumers: any frontend fetch caller (`src/frontend/src/api/` once it exists), the `@extend_schema` annotations, `docs/`, and any external client. Grep for the endpoint path and serializer name before changing them.

2. **Change the backend contract.** Edit the serializer/view. Keep DRF generic-CBV + explicit `path()` conventions (see `django-backend`). Update `permission_classes`, `pagination_class`, or filtering deliberately — these are part of the contract.

3. **Keep the schema accurate.** Update the `@extend_schema` / `@extend_schema_view` annotations to match the new request/response. Regenerate the schema to review the diff:
   ```bash
   docker compose -f compose.dev.yml exec django python manage.py spectacular --file schema.yml
   ```
   (No `schema.yml` is committed today. If you introduce one as the tracked contract, treat it as **generated — never hand-edit it**; regenerate instead.)

4. **Update consumers.** No client codegen exists, so update hand-written frontend fetch callers by hand to match the new shape/status codes. If none exist yet, note the endpoint in the PR so the frontend author has the contract.

5. **Check backward compatibility.** Adding an optional field or endpoint is safe. Renaming/removing a field, tightening validation, changing status codes, altering pagination, or narrowing permissions is **breaking** — call it out. Prefer additive changes; deprecate before removing.

6. **Contract tests.** Add/extend an `APITestCase` in `src/<app>/api/tests.py` asserting status code, response keys, and auth/permission behavior for the changed endpoint.

## Report

State the rollout risk explicitly: whether the change is additive or breaking, which consumers must ship together, and whether old clients keep working during deploy.
