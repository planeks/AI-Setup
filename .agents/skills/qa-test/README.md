# qa-test — a portable AI manual-QA engineer

You build features fast with Claude Code — faster than anyone can test them. This
is the manual QA engineer you don't have, packaged as a **reusable, app-agnostic
Claude Code skill**. Install it once on a developer machine; use it in *any* web
app repo.

Point it at a feature (headless by default; add `--headed` to watch it run):

```
/qa-test 'sign-up flow'            # headless
/qa-test 'sign-up flow' --headed   # visible browser
```

…and it reads *that app's own code* to figure out what a human QA would click,
drives the app like a real user in a browser, writes a **durable Python
`pytest-playwright` spec**, runs it, and **reports** whatever broke with evidence.
The committed spec is your regression net: fix the bug, re-run the spec, watch it
go green. (The app can be any stack — only the test is Python.)

## What it does (your 5 steps)

1. **Reads the feature's code** in the current repo — routes, components, every
   form field & validator, and the backend chains (jobs, webhooks, triggers) that
   feed user-visible results.
2. **Enumerates the cases** a human QA would test — happy paths, validation,
   empty/error states, auth, navigation, *and the observable end-states of async
   backend chains* (see below). Emits a reviewable `<feature>.plan.yaml`.
3. **Writes a Python `pytest-playwright` spec** in the app's natural place (the
   feature's own folder if it has one, else the app's test home) — the spec is
   always Python, whatever stack the app itself is. **3.5** — if a spec already
   exists, it diffs and updates it instead of duplicating.
4. **Runs the spec, then fixes what broke.** For each failure it reports
   expected-vs-observed + evidence, then triages: **real bug → it fixes the app**
   (smallest change, shows the diff) and re-runs; flaky → it stabilizes the wait;
   intentional change → it stops and asks. It **loops report → fix → re-run until
   the suite is green**, or until a fix needs a human decision.
5. **Final report**: every case's pass/fail, the bugs it fixed (cause + diff), and
   anything left open for you to decide. The committed green spec is your
   regression net — no external tracker needed.

It is **app-agnostic** — no per-app install, no assumptions about framework,
language, routing, or auth. It discovers all of that from the repo.

## The webhook question, answered

> "Webhooks, triggers, and backend side-effects aren't testable through a
> browser — Playwright only drives the UI."

Half true, and the wrong half matters. A human QA never opens the database — but
they absolutely test flows that *depend* on backend work, because that work
**surfaces back in the UI**: an aggregated total, a status badge that flips to
*Paid*, a file that downloads. This skill's core rule:

> **Discover the whole chain in code** (upload → job → totals, or
> action → remote service → webhook → status) so you know *what to expect and how
> long to wait* — then **assert only on the user-observable end-state** of that
> chain. Never on the DB, the queue, or the raw webhook payload.

If a chain has no observable end-state, the skill says so in the report instead of
faking a backend assertion. Full reasoning in
[references/observable-end-states.md](references/observable-end-states.md).

## Two guardrails that keep the tests honest

- **Code = surface area. Intent = oracle.** Code tells the AI *what to click and
  which cases exist* — never *what is correct*. The correct outcome comes from
  your feature description / acceptance criteria. If intent is genuinely
  ambiguous, it asks instead of guessing (so it never certifies a bug as "passing").
- **The AI stays out of re-runs.** Authoring a spec is AI-heavy and happens once
  per feature. Re-running it is a plain `playwright`/`pytest` command — cheap,
  deterministic, CI-friendly. The AI only re-engages on a failure, to triage:
  real bug vs. flaky vs. the feature legitimately changed.

## Install

```bash
./install.sh     # one shot: installs the skill, registers the Playwright MCP,
                 # and builds the ~/.qa-test/venv runner (pytest-playwright + Chromium)

# restart Claude Code, then — that's it — in ANY app:
cd path/to/any-app
claude
/qa-test '<feature>'
```

Prerequisites the script can't install for you: **Claude Code**, **Node 18+** (for
the MCP), **Python 3** (for the runner venv). It checks and warns if any are
missing. Full details in **[INSTALL.md](INSTALL.md)**.

## What's in this directory

```
SKILL.md                  the playbook Claude follows (this dir is the skill)
references/
  observable-end-states.md  the backend-chain principle (the differentiator)
  case-taxonomy.md          the QA case categories to enumerate
  playwright-authoring.md   locator/wait/assert/triage guidance
assets/
  conftest.py.template      pytest-playwright fixtures, dropped into apps with no config
examples/
  sign-up.plan.yaml         a sample reviewable test plan
install.sh                  symlink/copy the skill into ~/.claude/skills
INSTALL.md  README.md  DESIGN.md
```

## Roadmap

- **Now (attended):** Claude Code drives the whole flow via this skill. Nothing
  else required.
- **Later (unattended):** the same Playwright specs can be promoted into a
  headless runner to gate PRs / run nightly. Only the orchestrator changes; the
  specs carry over. See [DESIGN.md](DESIGN.md).
