# The observable-end-state principle

This is the load-bearing idea of the whole skill. Read it before you decide what
to assert.

## The objection it answers

> "Buttons and forms are testable through a browser. Webhooks, triggers, and
> backend side-effects aren't — Playwright only drives the browser, so step 2
> ('extract interactable moments') is the weak link."

This is half right and half wrong, and the wrong half is the important one.

**Right:** you do not, and must not, reach into the database, the message queue,
or the raw webhook payload. A manual QA tester doesn't have a SQL console open.

**Wrong:** that a flow involving a webhook is therefore untestable. Real features
are *designed so that backend work surfaces back to the user.* That surfacing is
exactly what QA verifies.

## The mental model

A human QA tester treats the app as a black box with two things they can touch:

- **inputs** they can perform (click, type, upload, navigate); and
- **outputs** they can observe (rendered text, numbers, status badges, toasts,
  enabled/disabled state, a downloaded file, a redirect).

Everything in between — endpoints, jobs, third-party services, webhooks — is
*opaque*, but its **effects are observable** or the feature would be pointless to
a user. So the rule is:

> Discover the entire chain in code so you know **what to expect** and **how long
> to wait**. Assert only on the **observable end-state** of that chain.

## Two worked examples (both from the user's own brief)

### File upload → processing → aggregation
- **Chain (found in code):** `<input type=file>` → POST `/reports` → background
  job parses the CSV → writes aggregates → results page renders totals.
- **What QA expects:** upload a *known* fixture and the rendered totals must match
  the numbers that fixture implies (e.g. `Revenue = 12,340`, `3 regions`).
- **Assert:** the totals table on the results page. Use a fixture you control so
  the expected numbers are deterministic.
- **Wait:** poll the "processing…/done" indicator or await the results table —
  never a fixed `sleep`.

### Action → remote service → webhook → status flip
- **Chain (found in code):** user clicks "Pay"/"Sync" → app calls a remote
  provider → provider calls our webhook → webhook handler flips an order/job
  **status**, which the UI shows as a badge.
- **What QA expects:** after the action completes, the status badge becomes
  *Paid* / *Completed* within a reasonable window.
- **Assert:** the status badge text in the UI.
- **Wait:** poll the badge with a generous timeout (these are async). If the env
  can't actually reach the remote provider, see "When the chain can't run live".

## How to assert on async end-states (mechanics)

- Use Playwright web-first assertions with their own timeout, e.g.
  `expect(page.get_by_test_id("order-status")).to_have_text("Paid", timeout=30000)`.
- Or poll a status endpoint/badge in a loop with a deadline.
- Use **deterministic fixtures** so expected numbers are fixed, not "whatever the
  code computed".
- Prefer the app's own "done" signal (a badge, a row count, a toast) as the wait
  condition.

## When the chain can't run live

Sometimes the third-party leg genuinely can't fire in the test environment (no
sandbox provider, no inbound webhook to localhost). Options, in order of
preference:

1. **Use the provider's sandbox/test mode** if the app supports it — then the real
   webhook fires and you assert the real end-state.
2. **Replay the webhook**: if the handler is a normal HTTP endpoint, the test can
   POST a realistic provider payload to it (this simulates the provider, not the
   browser), then assert the resulting UI status. Document that the provider leg
   is simulated.
3. **Declare it out of scope**: if neither is possible, do **not** fake a DB
   check. Note in the plan and report: "webhook end-state not verifiable in this
   environment" and test up to the last observable point (e.g. "redirected to
   provider" / "pending status shown").

## The bright line

| Allowed (observable) | Not allowed (opaque internals) |
|---|---|
| Rendered text, numbers, totals | Reading the database |
| Status badges / labels | Asserting a queue length |
| Toasts, banners, error messages | Inspecting the raw webhook JSON |
| Enabled/disabled, visible/hidden | Asserting an ORM object's fields |
| A downloaded file's contents | Asserting a log line |
| Redirects / final URL | Asserting internal function calls |

If your assertion lands in the right column, rewrite it to assert the left-column
effect it ultimately causes — or move the case out of scope.
