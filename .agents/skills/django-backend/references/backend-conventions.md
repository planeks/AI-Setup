# Backend conventions: transactions, locking, N+1, migrations

The repo does not use any of these patterns yet (no `transaction.atomic`, no `select_for_update`, stock auto-generated migrations only). Apply these rules when you introduce write-heavy endpoints, list endpoints, or non-trivial migrations.

## Transactions

Wrap multi-row writes so a partial failure rolls back:

```python
from django.db import transaction

with transaction.atomic():
    order = Order.objects.create(...)
    OrderLine.objects.bulk_create(lines)
```

- A single `Model.objects.create()` / `.save()` is already atomic — do not wrap it.
- Do not fire a Celery task from inside the block on the created object; the worker may run before commit. Use `transaction.on_commit(lambda: task.delay(obj.id))`.
- Keep the block short. Never do network I/O (email, HTTP) inside `atomic()`.

## Row locking

Use `select_for_update()` only when two concurrent requests could read-modify-write the same row (balances, counters, claim-one-of-N):

```python
with transaction.atomic():
    account = Account.objects.select_for_update().get(pk=pk)
    account.balance -= amount
    account.save(update_fields=["balance"])
```

`select_for_update()` requires an open transaction. Prefer `F()` expressions or a single `UPDATE` when you do not need to read the value first.

## N+1 avoidance

List and detail endpoints that traverse relations must prefetch:

- `select_related("fk_field")` for forward ForeignKey / OneToOne (SQL join).
- `prefetch_related("reverse_or_m2m")` for reverse FK and ManyToMany.

Set them on the view's `queryset` / `get_queryset()`, not per-serializer. The dev container has django-debug-toolbar — use it to catch query fan-out before merging.

## Migrations

- Generate with `makemigrations`; commit the migration file alongside the model change. Never hand-write auto-generatable migrations.
- Data migrations use `RunPython` with a paired reverse function (or `RunPython.noop`).
- CI runs a migration-conflict check (duplicate migration numbers on a branch). Rebase and regenerate rather than renumbering by hand.
- Ruff ignores the `migrations/` directory — do not reformat generated migrations to satisfy the linter.
