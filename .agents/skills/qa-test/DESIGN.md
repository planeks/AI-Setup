# Design — the AI QA engineer (qa-test)

An app-agnostic AI that acts as the manual QA engineer a team doesn't have. You
build a feature fast with Claude Code, then ask it to **test** that feature in the
current repo. It reads the app's code to learn the feature's surface and cases,
drives the app in a real browser, writes a **durable Playwright spec**, runs it,
and **reports** failures with evidence — you fix, re-run the committed test, and
watch it go green as a regression net.

## Why a Skill, not a custom server or framework

Claude Code is already an agent loop with everything this needs: file access and
code reading (native) and a browser (Playwright MCP). For the **attended** case —
a developer running `/qa-test` after building a feature — wrapping that in
LangGraph or a bespoke MCP server would be redundant ceremony. A **Skill** is just
a markdown playbook that encodes the workflow and points at the right tools. So:

- **Skill** = the brain/playbook (`SKILL.md` + `references/`). User-level, every
  project, zero per-app config.
- **Playwright MCP** = the hands (drive the browser via the accessibility tree).
- **Native Read/Grep/Glob** = code understanding of whatever app you're in.

Nothing is installed per app. You `cd` into a repo and run it.

## The two-loop model

The deliverable is a **committed Playwright spec**, not a live AI session. That
splits the system in two:

**Loop A — Authoring + fix** (slow, AI-heavy, once per feature)   
read code → enumerate cases → drive app → emit `<feature>.plan.yaml` + a committed
`<feature>.spec` → run it → **report failures → fix the real bugs in the app →
re-run → repeat until green** (or until a fix needs a human decision). The LLM
lives here. The inner report→fix→re-run loop is bounded and has one invariant:
**fixes land in the app, assertions stay pinned to the oracle** — a red test is
never made green by weakening it to match the bug.

**Loop B — Regression** (fast, deterministic, every change, **no AI**)
run the spec → report → on failure retain trace/video/screenshot as evidence.
Fix → re-run → green. The spec itself is the record of what's broken vs. fixed.

> The AI stays **out of Loop B**. A committed spec is cheap and stable; the LLM is
> expensive and non-deterministic. The AI re-engages only **on a failure**, to
> triage: real bug vs. flaky vs. feature legitimately changed (stale test). This
> keeps re-runs ~free and the suite trustworthy.

## The two rules that decide if it works

1. **Code = surface area, intent = oracle.** If assertions are derived from the
   code, the suite just certifies "what the code currently does" — bugs included.
   The feature description / acceptance criteria is the oracle for the *correct
   outcome*; code only reveals *what to click and which cases exist*. When intent
   is genuinely ambiguous, the skill **asks** rather than inventing an oracle.

2. **Test only what's observable — but follow the chain to its observable end.**
   This is the project's central technical stance and the answer to the "webhooks
   aren't testable" objection.

## The observable-end-state stance (the differentiator)

The objection: *Playwright only drives the browser, so backend side-effects —
webhooks, triggers, async jobs — can't be tested; "extract interactable moments"
is therefore the weak link.*

The rebuttal, which this design is built around:

- A human QA never reads the database — **but they test flows whose correctness
  depends on backend work**, because that work **surfaces back into the UI** as a
  number, a status badge, a rendered result, or a downloadable file.
- So the skill **reads the code to discover the entire chain**
  (upload → job → aggregation → totals; action → remote service → webhook →
  status flip) precisely because a user/QA is *expected* to know that chain and to
  expect a specific final number or status.
- It then **asserts only on the user-observable end-state** of that chain, and
  **waits on the observable signal** (poll the badge/results), never on a fixed
  sleep, never on the DB or raw webhook payload.
- If a chain has no observable end-state, it's declared **out of scope** in the
  report rather than faked.

This is why step 2 ("extract interactable moments") is *not* the weak link: the
skill extracts both the direct interactables **and** the backend chains, but only
ever verifies them where they become visible to a user. Full treatment in
[references/observable-end-states.md](references/observable-end-states.md).

## Artifacts & conventions

- `<test-dir>/<feature>.plan.yaml` — reviewable test plan; `expected` always comes
  from the oracle.
- `<test-dir>/test_<feature>.py` — committed Python `pytest-playwright` tests, one
  per case, keyed with a stable `[qa:<feature>:<case-id>]` in the function
  name/docstring. (Tests are always Python; the app under test can be any stack.)
- Playwright report + trace/video/screenshot — evidence cited in the failure
  report. The stable key ties each result back to its plan case.

**Where `<test-dir>` is** is decided per app: the feature's own folder if it has
one, else the app's natural test home (`tests/`, a Django app's `tests/`, `e2e/`,
or `playwright_tests/` at the root). The skill matches existing conventions and
never introduces a second test framework.

## Decisions taken in this build

- **Autonomous, one-shot run** (matching the original brief): the plan is emitted
  first so the user can see/interrupt it, but the run proceeds on its own. The one
  hard stop is *ambiguous intent* — it will not assert a guessed oracle.
- **Per-app test location**, chosen by Claude from the app's structure.
- **Python `pytest-playwright` specs always**, regardless of the app's own stack —
  one language to read, run, and maintain. Authoring still uses the Node Playwright
  MCP (`npx`) to drive the browser; that's an authoring-time tool, not a JS runner.

## Roadmap / phase 2 (unattended)

When you want this to gate PRs or run nightly **without a human**, promote the same
Loop B into a headless runner. That's where an orchestrator (e.g. LangGraph) earns
its place — for cycles (re-probe on failure), checkpointing (resume a long suite),
and explicit state passing (plan → specs → results → report). The Playwright specs
and the stable-key logic carry over unchanged; only the orchestrator is added.

## Open product questions

- A standard auth strategy across apps (shared test account vs. per-app saved
  `storage_state`).
- Whether to keep a small library of reusable fixtures (known CSVs, seed users)
  for deterministic async-chain assertions.
