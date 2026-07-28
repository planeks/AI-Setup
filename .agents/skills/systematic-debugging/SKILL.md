---
name: systematic-debugging
description: Disciplined debugging workflow — reproduce, capture expected vs actual, localize, inspect, form testable hypotheses, change one variable at a time, add a regression test, fix the root cause. Use when a bug, failing test, exception, or wrong behavior needs diagnosis rather than a guessed patch.
---

# Systematic debugging

Diagnose before you change. A patch that hides the symptom without a named root cause is not a fix.

## Workflow

1. **Reproduce.** Find the smallest reliable trigger — a failing test, a request, a management command. If you cannot reproduce it, you cannot verify a fix.
2. **State expected vs actual.** Write down the concrete observed behavior and the concrete expected behavior, with real values.
3. **Localize.** Narrow to the smallest area: which app/module, which view/serializer/task/component. Use the stack trace's top in-repo frame.
4. **Inspect real signals**, don't guess:
   - Logs: `docker compose -f compose.dev.yml logs -f django` (or `celeryworker`).
   - Django state: `docker compose -f compose.dev.yml exec django python manage.py shell`.
   - DB: query directly in the shell / `dbshell` to check the actual stored rows.
   - Email: MailHog UI at `http://localhost:8025`. Celery tasks: Flower at `http://localhost:5555`.
   - Frontend: browser devtools console + network tab; `@sentry/react` if configured.
5. **Form a testable hypothesis.** "X is null because the serializer drops it when Y" — something you can confirm or refute with one observation.
6. **Change one significant variable at a time.** Re-test after each. Reverting a batch of guesses teaches nothing.
7. **Add a regression test** that fails before the fix and passes after — `TestCase`/`APITestCase` for backend, Vitest for frontend (see `django-backend` / `react-frontend`).
8. **Verify** with the narrowest sufficient checks (see `verify-change`), including the reproduction from step 1.
9. **Fix the root cause.** If you must ship a mitigation, say so and name the underlying cause and the follow-up.

Report using the `concise-engineering-output` closing format: root cause, fix, verification, and anything still unverified.
