# Playwright authoring guide

How to turn a confirmed flow into a durable, commit-quality spec. The goal is a
test that fails **only** when the feature is actually broken — not when a class
name changed.

**Specs are always Python `pytest-playwright`** (sync API). The app under test can
be any stack; the committed test is Python. All examples below use that API.

## Author with the MCP first, then freeze

Use the Playwright MCP to walk the real flow via the accessibility tree before
writing anything. The a11y tree gives you the same handles a human (and a screen
reader) use — roles, names, labels — which are far more stable than CSS. Confirm
each locator works live, then write it into the spec.

## Locator strategy (most → least preferred)

1. **Role + accessible name** — `page.get_by_role("button", name="Sign up")`,
   `page.get_by_role("textbox", name="Email")`. Survives restyling and refactors.
2. **Label / placeholder / text** — `page.get_by_label("Password")`,
   `page.get_by_text("Verify your email")`.
3. **`data-testid`** — `page.get_by_test_id("order-status")`. If the app lacks test
   ids on a critical-but-unnameable element, it is reasonable to ask the dev to add
   one; prefer it over a brittle CSS path.
4. **CSS / XPath** — last resort. A CSS selector tied to layout/utility classes is
   a future false failure. Avoid `.css-1x2y3z`, deep `div > div > span`, nth-child.

## Waiting — never sleep

- Use **web-first assertions** (`from playwright.sync_api import expect`); they
  auto-retry until their timeout: `expect(locator).to_be_visible()`,
  `.to_have_text()`, `.to_have_url()`.
- For async backend chains, give the assertion a generous explicit timeout and
  wait on the **observable signal** (a status badge, a results row, a toast):
  `expect(page.get_by_test_id("order-status")).to_have_text("Paid", timeout=30000)`.
- Use `page.wait_for_url()` / `page.wait_for_load_state()` over arbitrary delays.
- **Never** `page.wait_for_timeout(3000)` as a real wait. Fixed sleeps are the #1
  source of flaky specs and slow suites.

## Assertions = the oracle, not the code

Each test asserts the **intended** outcome from the feature description /
acceptance criteria. Do not read the component to find "what message it shows" and
assert that — if the message is wrong, you'd be certifying the bug. When intent is
unclear, the case should have stopped you to ask during planning.

## Data-driven cases — parametrize over a fixture directory

When the user points at a folder of example inputs, make **one case per file** with
`pytest.mark.parametrize`, so adding a fixture adds a case for free and each file's
result is asserted on its own:

```python
from pathlib import Path
import pytest

FIXTURES = sorted(Path("data/dev/staticfiles/ai-expenses-detection").glob("*.csv"))

@pytest.mark.parametrize("expense_file", FIXTURES, ids=lambda p: p.stem)
def test_qa_expense_intake_imports_each_file(page, expense_file):
    """[qa:expense-intake:import-<file>] each example file imports its records."""
    # … upload expense_file, drive the wizard to finalize …
    expect(page.get_by_text("Imported")).to_be_visible()
    # assert the per-file expected count (keep a small {filename: N} map as the oracle)
```

- Give each param a readable `id` (`ids=lambda p: p.stem`) so the report shows
  `…[QB042026]`, `…[partial-missing-vendor]`, etc. — that becomes the case id.
- The **expected count/outcome per file is the oracle** — keep a small map of
  `filename → expected`, don't assert "whatever the importer produced".
- For files that hit a **real LLM / paid API**, gate the heavy params behind a
  marker/env flag (`@pytest.mark.skipif(not os.environ.get("QA_RUN_LLM"), …)`) — but
  still run them live once while authoring, and report them as gated, not skipped.

## Determinism

- Use **fixtures you control** (a known CSV, a known user) so expected numbers and
  statuses are fixed values, not "whatever the code produced".
- Seed/clean state per test where the app allows it; otherwise make tests
  independent and order-free.
- Avoid depending on real wall-clock time, random data, or external state you
  can't pin.

## Secrets & auth

- Read credentials from **env vars** or a **gitignored** Playwright
  `storage_state` file. Never commit secrets into a spec.
- For logged-in flows, prefer a saved `storage_state` (log in once, reuse) over
  logging in through the UI in every test — keep one explicit login test for the
  auth flow itself.

## Structure & naming

- **One test per plan case.**
- The function name + docstring carry the stable key that ties a result back to
  its plan case:
  `def test_qa_sign_up_happy_path(page):` with a `"""[qa:sign-up:happy-path] new
  user can register."""` docstring.
- Group a feature's tests in one file (`test_<feature>.py`); use a `class
  TestSignUp:` if the framework's convention favors it.
- Keep steps readable; extract a shared `sign_up(page, data)` helper or a pytest
  fixture when several tests repeat a flow.

## Evidence on failure

`conftest.py.template` + the run flags enable **trace, video, and screenshot on
failure** — these are the artifacts you cite in the failure report. Run **only the
feature's spec file** (not the directory, not the whole suite):
```
~/.qa-test/venv/bin/pytest tests/test_<feature>.py --rootdir=tests \
  --tracing=retain-on-failure --screenshot=only-on-failure --video=retain-on-failure
```
Narrow to a single case while iterating with `-k <case-id>`. Open a saved trace
with `playwright show-trace <trace.zip>`.

## Triage when a committed spec later fails

A red spec is one of three things — decide which before touching code or test:
1. **Real bug** — app violates the oracle. **Report it (evidence path), then fix
   the app** with the smallest change that meets the intended behavior, and re-run.
   Do **not** change the test to match the buggy output — that certifies the bug.
2. **Flaky** — passes on retry, timing-sensitive. Fix the wait (web-first
   assertion / better signal), not by adding a sleep.
3. **Stale** — the feature *intentionally* changed and the spec's oracle is now
   outdated. This is a human decision: confirm the new intent with the user before
   changing any assertion, then update the plan & spec.

This triage is the heart of the **report → fix → re-run loop** in `SKILL.md` step
5: fix real bugs in the app, stabilize flakes in the spec, and stop to ask on stale
tests or any fix that needs a product/architecture decision.
