# CLAUDE.md — Architecture (PLANEKS)

> Cross-cutting code-organization rules. Read alongside the framework-specific file.
> Operational concerns (hosting, CI policy, on-call, backups, SLOs) live in the team wiki — they don't change what Claude writes.

---

## Code principles

- **Boring is good.** Prefer well-understood, well-supported patterns over novel ones unless there's a concrete reason.
- **Don't over-engineer.** Solve the task in front of you; don't add abstractions for hypothetical future needs.
- **Make the implicit explicit.** Surface hidden coupling, magic config, and undocumented invariants in code and names — not in tribal knowledge.
- **Dependencies point inward.** Domain doesn't import from infrastructure. Presentation doesn't bypass services to hit the DB.

## Layers (typical web app)

```
┌──────────────────────────────────────────┐
│ Presentation (HTTP/UI)                   │  routes, controllers, components
├──────────────────────────────────────────┤
│ Application services                     │  use-cases, orchestration
├──────────────────────────────────────────┤
│ Domain                                   │  entities, business rules
├──────────────────────────────────────────┤
│ Infrastructure                           │  DB, queues, external APIs, FS
└──────────────────────────────────────────┘
```

- For small projects, collapse layers — don't invent ceremony you won't use.
- For medium+, keep them separate.

## Module boundaries

- Organize by **feature/domain**, not by layer alone. `users/`, `billing/`, `notifications/` — each owns its models, services, routes, tests.
- Cross-feature calls go through public service interfaces, not direct DB access into another feature's tables.
- Shared code → `core/` / `common/`. Pull something in only when it's used by 2+ features.

## Business logic placement

- **Services** own write paths (`create_order`, `charge_customer`, `send_invite`).
- **Selectors / queries** own read paths (list users with filters, dashboard aggregates).
- **Models / entities** hold data + invariants (validation that's always true regardless of caller).
- **Controllers / routes / views** translate HTTP ↔ services. They don't decide business rules.

## API design

- REST by default for CRUD. GraphQL when clients need flexible read shapes. gRPC for service-to-service in polyglot environments.
- **Version from day one:** `/api/v1/...`. Break only by bumping the version.
- **Pagination on every list endpoint.** Default page size, max page size, cursor or offset (cursor for large datasets).
- Filtering / sorting via query params with **allow-lists** — never accept arbitrary field names from the client.
- **Idempotency keys** on POSTs where retries could duplicate (payments, mutations).
- Status codes: 200 read, 201 create, 204 delete, 400 bad input, 401 auth missing vs 403 forbidden, 409 conflict, 422 validation.

## Data & persistence

- **SQL first.** Reach for NoSQL only when the access pattern doesn't fit SQL (graph, geo, full-text-only, time-series at scale).
- **PostgreSQL** is the default relational DB.
- Use **Redis** for caching, session storage, queues, rate limiting, ephemeral data.
- Use **MongoDB** when the data is genuinely document-shaped with evolving schema.
- **Migrations** for schema changes — never edit a production DB by hand.
- Design indexes with queries in mind, not afterwards. Check query plans on slow queries.
- Soft delete vs hard delete: pick one per entity and apply it consistently.

## Caching

Cache invalidation is the hard part. Prefer in this order:

1. **Short TTLs** (seconds–minutes) when mild staleness is acceptable.
2. **Explicit invalidation on writes** when staleness isn't acceptable.
3. **Versioned cache keys** to avoid stale reads after deploys.

- Never cache user-specific data without including the user in the key.
- For HTTP, use `ETag` / `Cache-Control` for cacheable GETs.

## Async / background work

- HTTP handlers should return fast. Anything > ~1s of work → background job.
- Tasks must be:
  - **Idempotent** — they will retry.
  - **Small** — one logical action.
  - **Logged** with a correlation ID.
- Dispatch **after** the DB commit (`transaction.on_commit` in Django, equivalent in other frameworks) — otherwise the worker may read stale state from a replica.
- Pass IDs to tasks, not ORM objects (objects detach from sessions and may be stale).

## Multi-tenancy

When the app serves multiple tenants:

- Pick isolation level **once**, at the start: column-based (cheapest), schema-per-tenant (middle), DB-per-tenant (strongest isolation, highest overhead).
- All queries filter by tenant. Enforce in a base manager/repository — not per-call.
- Tests cover cross-tenant access attempts and ensure they fail closed.

## Configuration

- **12-factor:** config via env vars, not files committed to the repo.
- One config object loaded at startup. **Validate at startup** — fail loud on missing/invalid values.
- Different envs (dev, staging, prod) differ only in config, not code.

## Secrets

- Never in code, never in committed files. Env vars (with `.env` gitignored) in dev.
- In production, a secrets manager (AWS Secrets Manager, Vault, Doppler) — but that wiring is set up before Claude is involved; just read from the env.

## Observability (code-level)

When adding logging or error tracking in code:

- **Structured logs** (JSON) with a correlation/request ID. No secrets, no raw request bodies that may contain them, no PII.
- Use the framework's recommended logger. Never `print()` for production paths.
- For uncaught exceptions, **Sentry SDK** (`sentry-sdk`) is the project default — initialize it once at startup, then it captures automatically.
- Tag releases and environments in the Sentry init.

Health endpoints:

- `GET /healthz` — liveness (process is up).
- `GET /readyz` — readiness (DB, Redis, critical deps reachable).
- Both return cheap JSON, no auth.

## Resilience (code patterns)

When calling external services:

- **Timeouts** on every outbound call. Connect timeout + read timeout, separately.
- **Retries** with exponential backoff + jitter on retryable errors. Cap attempts.
- **Circuit breakers** for dependencies that can take down the system.
- **Graceful degradation** — if a recommendations service is down, the product page still renders.
- **Idempotency** on retried operations to avoid duplicates.

## Performance

- Measure before optimizing. Slow queries are usually the culprit.
- Optimization order: pagination → indexes → denormalize. Caching is a tool, not a fix for a bad query plan.
- Connection pooling for DB and HTTP clients.
- Detect N+1 in dev (debug toolbar, query loggers, tests that assert query counts).

## Security architecture (code-level)

- **Defense in depth:** input validation + parameterized queries + output escaping + CSP — not just one.
- **Least privilege** in code paths: a service that only reads should hold a read-only DB role; per-service IAM roles in cloud calls.
- **Authn vs Authz separated.** Centralize authorization checks in services/middleware, not scattered across controllers.
- **Audit logging** for sensitive actions: who did what, when, to what entity.
- Always validate / sanitize HTML you render from user input. Avoid `dangerouslySetInnerHTML` / `mark_safe` without a clear reason.

## When to introduce complexity

Default to a **modular monolith** with clear feature boundaries. Split out a service only when:

- An independent scaling axis demands it.
- A different team owns it end-to-end.
- It needs a different language/runtime for a good reason.

Avoid by default:

- **Microservices** without org/scale pressure — two services with a shared DB are worse than a modular monolith.
- **Event sourcing / CQRS** — niche; almost never the right starting point.
- **Custom infrastructure** when managed services fit.

---

## Decision quick-reference

| Question                                | Default answer                          |
|-----------------------------------------|-----------------------------------------|
| SQL or NoSQL?                           | SQL (Postgres) unless shape demands NoSQL |
| Monolith or microservices?              | Modular monolith                        |
| REST or GraphQL?                        | REST unless clients need flexible reads |
| Sync or async API handler?              | Whichever the framework prefers; don't mix |
| Cache or fix the query?                 | Fix the query first                     |
| Where do business rules live?           | Services / domain, not controllers      |
| External API call fails — what now?     | Timeout + retry + circuit breaker + fallback |
| Where do secrets live in code?          | Read from env vars; never hardcoded     |
| Add a new abstraction?                  | Only when 2+ concrete use cases exist   |

---

## Anti-patterns

- "Generic" / "flexible" abstractions built for hypothetical future needs.
- Distributed monolith — many services that must deploy together.
- Business logic split across triggers, signals, ORM hooks, and services — no single place to read it.
- Long-running transactions holding DB locks.
- Catch-all `except` / `catch` that suppresses errors to "stabilize" production.
- Shared mutable state across requests (module-level dicts, singletons holding per-request data).
- "We'll add tests later." Later doesn't come.
- Cargo-culting patterns from large companies (Netflix, Google) without their scale, team, or constraints.
