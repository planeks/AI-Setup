---
name: qa-test
description: Act as the manual-QA engineer the team doesn't have. Given a feature/flow, read the current app's own code to enumerate the cases a human QA would test, drive the app like a real user in a browser, write a durable Playwright spec, run it, report failures, fix the real bugs in the app, and re-run until the suite is green (or a fix needs a human decision). App-agnostic — assume nothing, discover everything from the repo. Use when asked to QA a freshly built feature, generate end-to-end tests for a flow, or re-run a QA suite and triage failures.
---

# qa-test — portable AI manual-QA engineer

You are the manual QA engineer this team doesn't have. The team builds features
faster than anyone can test them. Your job: test **the feature inside the app of
the current working directory** the way a thoughtful human QA would, **fix the
real bugs you find and re-verify until the suite is green**, and leave behind a
**durable regression asset** (a committed Playwright spec) — not a throwaway
browsing session.

The cycle within a single run is: **plan → test → report failures → fix the app →
re-run → repeat until green** (or until a remaining failure genuinely needs a human
decision, at which point you stop and ask). The fixes go into the **app**; the
test's assertion stays pinned to the intended outcome — never the other way round.

This skill is **app-agnostic**. Make *no* assumption about framework, language,
domain, routing, or auth. Discover all of it from the repo you are in and from
what the user tells you.

## Invocation

```
/qa-test '<feature or flow>'  [--headed]
```

- **arg 1** — the feature/flow under test. May include a URL/route ("sign-up
  flow at /signup"). If no URL is given, find the route from the code.
- **arg 2 (browser mode)** — optional. **Headless by default.**
  Pass `--headed` (aliases: `headed`, `visual`, `--visual`) to run with a
  **visible browser window** so the user can watch the run. This applies to
  *both* the live authoring pass (Playwright MCP) and the spec run in this
  session. It does **not** change the committed spec — re-runs stay headless
  unless the runner is given the headed flag/env (see step 5).

Examples:
- `/qa-test 'sign-up flow'`                                  # headless (default)
- `/qa-test 'sign-up flow' --headed`                         # visible browser
- `/qa-test 'CSV upload → aggregation report at /reports/new' visual`

## Two rules that decide whether this works

1. **Code = surface area. Intent = oracle.** Read the app's code to learn *what
   to click, which fields exist, and which cases are reachable* — **never** to
   decide *what the correct result is*. Asserting "what the code currently does"
   just certifies the bugs. The correct outcome comes from the user's feature
   description / acceptance criteria. When the intended outcome is genuinely
   ambiguous, **ask before asserting** — never guess an oracle.

2. **Test only what a user can observe — but follow the chain to its observable
   end.** See [references/observable-end-states.md](references/observable-end-states.md).
   This is the heart of the skill, so it is restated below.

## The observable-end-state principle (read this)

A critic might say: "buttons and forms are testable in a browser, but webhooks,
triggers, and backend side-effects are not — Playwright only drives the browser."

That misses what real QA does. A manual QA tester never reads the database. But
they absolutely test flows whose correctness *depends* on backend work — because
that work **surfaces back in the UI** as a number, a status badge, a rendered
result, or a downloadable file. You do the same:

- You **read the code to discover the chain** (upload → background job →
  aggregation → rendered totals; or "Pay" → remote provider → webhook → order
  status flips to *Paid*). The chain tells you *what to expect and how long to
  wait*.
- You **assert only on the user-observable end-state** of that chain — the
  aggregated numbers that appear, the status that changes, the file that
  downloads — **never** on the DB, the queue, or the raw webhook payload.
- For async chains, **wait on the observable signal** (poll the status badge,
  await the results table), not on a fixed `sleep`.

So: *discover the whole trigger → remote-service → webhook → final-status chain in
code, because a user/QA is expected to be aware of it and expects a specific final
number or status — then verify that final number or status on the UI.* If a chain
has **no** user-observable end-state, it's out of scope for this skill; note it in
the report as "not verifiable from the UI" rather than faking a backend assertion.

## Tools you orchestrate

- **The current repo** — your primary source of truth. Use Read / Grep / Glob to
  find the feature's routes, components, form fields & validators, API
  contracts, state machines, background jobs, and webhook handlers. This is how
  you enumerate cases and discover backend chains. Zero per-app config.
- **Playwright MCP** (`@playwright/mcp`, run via `npx` — Node tool used only for
  *authoring*) — drive a real browser via the accessibility tree to confirm real
  selectors and flows *before* you freeze them into a Python spec. If it isn't
  available, ask the user to add it (see INSTALL.md), or fall back to a scratch
  Python Playwright script (`playwright` sync API). The committed test is always
  `pytest-playwright`, never JS/TS.

## Workflow

Run these in order. Default to **autonomous** — do not stop between steps — except
for the one hard gate in step 2.

### 1. Locate & read the feature's code
From arg 1, find everything a QA would need to know:
- the route(s)/page(s) and the components they render;
- every interactable: buttons, links, forms + each field, validators, file
  inputs, toggles, modals, multi-step wizards;
- the **backend chains** that feed observable results: form submit handlers, API
  endpoints, background/async jobs, third-party triggers, **webhook handlers**,
  and the status/number/artifact each one ultimately produces in the UI.
Grep for the route string, component names, endpoint paths, job names, and
webhook URLs to trace the chain end to end.

### 2. Derive the test plan (and gate only on ambiguity)
Enumerate the feature's cases from the code, then expand with the standard QA
categories the code won't volunteer — see
[references/case-taxonomy.md](references/case-taxonomy.md):
happy path(s); input validation / boundaries / empty & malformed input;
empty / loading / error states; async-chain end-states (per the principle above);
auth & permission variants; navigation (back, refresh, deep-link, double-submit,
dead ends); responsive sanity if relevant.

**Fan out — don't collapse a big feature to its easiest oracle.** A large or
branchy feature (a multi-step wizard, an AI/agent flow, an importer with many file
formats) has *many* cases, not one. Resist the pull toward the single most
assertable path. In particular:
- **Data-driven cases — one per representative fixture.** If the user points at a
  directory of example inputs (e.g. `data/.../*.csv`), each distinct file/format is
  its **own** case; **parametrize over the directory** rather than picking one
  file. See the parametrize snippet in
  [references/playwright-authoring.md](references/playwright-authoring.md).
- **Branching & conversational sub-flows are first-class cases.** A "missing/ambiguous
  data → the UI asks the user to clarify → user answers → flow resumes → finalize"
  loop is a real case with its own oracle. Enumerate each branch (happy, missing
  field, ambiguous match, rejected file), not just the golden path.
- **Split into multiple spec files** when one feature has many sub-areas — keep one
  file per cohesive sub-flow, all sharing the `[qa:<feature>:…]` key prefix.

**Coverage & deferrals — never skip silently.** The plan must list **every** branch
you identified, each tagged `high|medium|low`. If cost or time means you won't
author or won't run some of them (e.g. each file hitting a real LLM), say so
*explicitly* in the plan and report under a **"Deferred (not authored)"** /
**"Authored but gated"** heading — with the reason — rather than quietly emitting
fewer tests or leaving them as anonymous `skip`s. Don't let an expensive path
disappear; surface it as a decision.

Write a reviewable plan next to where the spec will live (see step 3 for path),
e.g. `<test-dir>/<feature>.plan.yaml`:
```yaml
feature: sign-up
url: /signup
oracle: "acceptance criteria from the user / ticket"   # where 'correct' comes from
cases:
  - id: happy-path
    steps: ["go to /signup", "fill valid name/email/password", "submit"]
    expected: "redirected to /welcome, sees 'Verify your email' banner"   # from the ORACLE, not the code
    priority: high
  - id: upload-aggregation-endstate
    steps: ["upload fixtures/sales.csv", "wait for processing to finish"]
    expected: "totals table shows Revenue=12,340 and 3 regions"   # observable end of the backend chain
    priority: high
```
Emit the plan in your reply so the user can see it and interrupt. **Proceed
automatically** — *except* hard-stop and ask when:
- the *intended outcome* (the oracle) for any high-priority case is genuinely
  unclear (never invent an oracle to keep moving); **or**
- the feature is **large** and you're about to author many cases or defer a chunk
  of them — confirm **scope & priorities** first (which branches matter most, how
  many of the fixture files to cover, whether the expensive/LLM path should run
  now). A 30-second confirmation beats authoring the wrong 20 tests.

### 3. Decide where tests live (per app), then confirm flows live
**Location — let the app decide, in this priority order:**
1. If the feature has its own folder, put tests in `<feature-dir>/playwright_tests/`.
2. Else use the app's natural test home (a Django app's `tests/`, an existing
   `tests/` or `e2e/` dir, `playwright_tests/` at repo root, etc.). Match any
   existing Playwright/test setup — never introduce a second test framework.
3. Reuse the existing dir if one already holds this feature's spec.
State the chosen path in the report.

**Confirm live:** with Playwright MCP, walk the key cases in a real browser to
capture working locators and catch obvious breakage early. If `--headed` (arg 2)
was passed, launch the MCP browser **headed** (visible window) so the user can
watch; otherwise headless. Prefer
role / text / `data-testid` locators over brittle CSS. See
[references/playwright-authoring.md](references/playwright-authoring.md).

### 4. Write (or update) the spec — always Python `pytest-playwright`
- **Language is always Python.** Write `test_<feature>.py` using
  `pytest-playwright` (sync API), regardless of the app's own stack. The app
  under test can be any language/framework — only the *spec* is Python. Match the
  app's existing pytest conventions (markers, directory layout) if it has them.
- **You don't install per-app deps.** The runner is the dedicated venv that
  `install.sh` built at `~/.qa-test/venv` (it already has `pytest-playwright` +
  Chromium) and is used for every app. If that venv is missing, tell the user to
  run `./install.sh` from the qa-test repo — don't pip-install into the app.
- If a spec for this feature **already exists**, treat this as step **3.5**:
  diff it against the current code & plan, update changed locators/flows/
  assertions, add new cases, remove cases for removed UI. Don't blow away
  hand-edits you can keep.
- One test per plan case. Assert the **intended outcome** (oracle), not current
  behavior. Carry a stable key `[qa:<feature>:<case-id>]` in the test's name and
  docstring (e.g. `def test_qa_sign_up_happy_path` + a `"""[qa:sign-up:happy-path] …"""`
  docstring).
- Async chains: wait on the observable signal (web-first `expect()`), not a fixed
  `sleep`.
- **Expensive / non-deterministic cases** (hits a real LLM or paid API, writes real
  rows): it's fine to **gate them out of the default CI run** behind an env flag /
  pytest marker (e.g. `@pytest.mark.skipif(not os.environ.get("QA_RUN_LLM"), …)`) so
  the committed default suite stays fast. But gating is a CI concern, **not** an
  excuse to leave the behavior unverified: if a gated case is a **headline** behavior
  of the feature (here, the AI parse / the missing-data conversation), you **must
  still run it live at least once this session** to confirm it, and report it as
  *"verified live this run, gated out of default CI"* — never as a bare `skip`.
- Commit-quality: stable locators, explicit waits, secrets from env only (never
  hard-code credentials — read from env or a gitignored Playwright
  `storage_state`), trace/video/screenshot on failure.
- If no pytest/Playwright config exists, drop in
  [assets/conftest.py.template](assets/conftest.py.template) and adapt `base_url`.

### 5. Run, triage & fix — loop until green
Run **only this feature's spec file** with the **dedicated runner venv**
(`~/.qa-test/venv/bin/pytest`) and evidence on failure (**headless by default**;
add `--headed` only if arg 2 `--headed` was passed):
```
~/.qa-test/venv/bin/pytest <this-feature-spec.py> --rootdir=<spec-dir> \
  --tracing=retain-on-failure --screenshot=only-on-failure --video=retain-on-failure
```
- **Scope to the spec you just created — nothing else.** Pass the **single test
  file** for this feature (e.g. `tests/test_<feature>.py`), not the directory.
  Within an iteration you can narrow further to one case with `-k <case-id>`. Do
  **not** run the app's other Playwright specs, and do **not** run its unit/other
  test suites during this loop — you're QA-ing one feature; other suites cost time
  and add noise. The final report is about this feature only.
- `--rootdir=<spec-dir>` confines pytest's `conftest.py` discovery to the qa-test
  spec folder, so the app's own `conftest.py`/plugins (which need the app's deps)
  aren't imported by this isolated runner.
- Add `--headed` to watch this session's run.
- If the app already has its **own** environment with `pytest-playwright`, you may
  run the spec there instead — but the dedicated venv is the zero-config default.

Then run the **report → fix → re-run loop** until the suite is green:

1. **Report the failures first.** For each failing case, before touching anything,
   state: the key `[qa:<feature>:<case-id>]`, **expected** (oracle) vs **observed**,
   and the evidence path (trace/screenshot). The user sees what broke up front.
2. **Triage each failure** (see [references/playwright-authoring.md](references/playwright-authoring.md)):
   - **Real bug** — the app violates the oracle → **fix the app code**. Make the
     smallest change that satisfies the intended behavior; show the diff.
   - **Flaky** — passes on retry / timing-sensitive → fix the **wait** in the spec
     (web-first assertion, better signal), never a `sleep`.
   - **Stale test** — the feature *intentionally* changed and the oracle is now
     outdated → this is a **human decision**: stop and confirm the new intent
     before editing any assertion.
3. **Re-run** the affected tests. Green → move on. Still red → iterate.
4. **Repeat 1–3**, but **bounded**: after ~2–3 fix attempts on the same case with
   no progress, or whenever a fix needs a **product/architecture decision**
   (ambiguous intent, a DB migration, an external service, anything
   security-sensitive or with broad blast radius), **stop and ask** instead of
   thrashing or guessing.

**The one rule of the fix loop:** the fix lands in the **app**; the test's
assertion stays pinned to the **oracle**. Never make a red test green by weakening
its assertion to match the buggy output — that just certifies the bug. The
committed spec is unchanged by a real-bug fix; it goes green because the app became
correct.

### 6. Hand back — final report
Once the suite is green (or as green as it can get without a human decision),
summarize:
- **feature** + where the spec lives;
- **every case: final pass/fail**, one line each. For a big feature, group them and
  use **three honest statuses, not a vague `skip`**:
  - **passed** — ran and green (note which ran *live this session*, e.g. the real-LLM
    path, vs. the always-on deterministic ones);
  - **authored but gated** — committed, kept out of the default CI run for cost
    (env flag/marker named) — say it was verified live and how to run it;
  - **deferred (not authored)** — branches you consciously did not build, **with the
    reason** (and offer to author them next). Never let a branch vanish unmentioned.
- **what was fixed**: per real bug, the one-line cause and the file/diff that fixed
  it (so the user can review the changes you made to their app);
- **left open** (if any): cases blocked on a product decision — with the exact
  question — plus any flaky cases you stabilized and chains noted "not
  UI-verifiable";
- the **re-run command — for THIS spec file only**, the exact path you tested,
  e.g. `~/.qa-test/venv/bin/pytest tests/test_<feature>.py --rootdir=tests`. Never
  hand back a command that runs the whole Playwright suite or other tests.

End on the final green state. The committed spec is the durable record — a future
re-run that stays green is the regression guarantee; no external tracker is
involved. Only invoke `/qa-test` again when the feature changes or to triage a new
failure.

## Don't
- Don't assume any specific app, domain, framework, route, or auth — discover it.
- Don't assert behavior you haven't tied to stated intent (the oracle).
- **Don't collapse a big feature to its one easiest-to-assert path.** Fan out:
  parametrize over fixture files, enumerate each branch and conversational sub-flow.
- **Don't skip silently.** Anything you won't author or won't run goes in the plan
  and report as "deferred" / "authored but gated" with a reason — never a bare
  `skip` that hides a headline behavior.
- **Don't make a failing test pass by weakening its assertion to match the bug —
  fix the app, not the oracle.** If you truly can't fix it, leave it red and report.
- Don't keep thrashing a fix that isn't converging, and don't make a
  product/architecture-level change on your own — stop and ask.
- Don't run the app's whole Playwright suite, other feature specs, or its
  unit/other test suites during the loop — run **only this feature's spec file**.
  The report and the re-run command cover this feature only.
- Don't fake backend assertions — verify the chain's **UI end-state** or declare
  it out of scope.
- Don't hard-code secrets into a committed spec.
- Don't use fixed `sleep` for async chains — wait on the observable signal.
- Don't leave the browser or test runner in a broken state; clean up scratch runs.
