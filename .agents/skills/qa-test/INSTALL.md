# Install & setup

One command sets up everything. After that, every app "just works": `cd` into it,
run `claude`, use `/qa-test`. No per-app setup, no virtualenvs to manage.

## Prerequisites (the only things `install.sh` can't install for you)

- **Claude Code** (the `claude` CLI) — installed and logged in.
- **Node.js 18+** (`node`/`npx` on PATH) — the Playwright **MCP** (the authoring
  browser) is a Node tool.
- **Python 3** (`python3`) — used to build the dedicated test-runner venv.

`install.sh` checks for each and prints a clear warning if one is missing, but it
can't conjure them. Everything else it handles.

## Install (one shot)

From this directory (`.agents/skills/qa-test/`):

```bash
./install.sh
# or:  ./install.sh --copy   # copy the skill instead of symlinking it
```

That single run does **three** things:

1. **Installs the skill** → `~/.claude/skills/qa-test` (symlink by default, so repo
   edits take effect live; `--copy` for a standalone copy). Available in **every**
   project automatically. Any existing install is backed up first.
2. **Registers the Playwright MCP** at user scope, pinned to one release
   (`claude mcp add --scope user playwright -- npx -y @playwright/mcp@0.0.83`) — the
   Node browser used **only while authoring** specs. It's not a test runner and manages
   its own browser. A registration this installer wrote earlier, at another version or
   at `@latest`, is moved to the pin; one you set up by hand is left alone.
3. **Builds the test-runner venv** at `~/.qa-test/venv` with `pytest-playwright`
   + Chromium. This one venv runs the Python specs for **every** app, so you never
   install per-app deps. (Specs are black-box — they drive the app over its URL and
   don't import the app's code — so one shared runner works everywhere.)

Re-running `./install.sh` is safe and idempotent. Overrides:

```bash
CLAUDE_DIR=/custom ./install.sh     # different ~/.claude
QA_TEST_HOME=/custom ./install.sh   # different home for the runner venv
PYTHON=python3.12 ./install.sh      # pick the interpreter for the venv
PLAYWRIGHT_MCP_VERSION=0.0.84 ./install.sh   # register another Playwright MCP release
```

<details>
<summary>What if I don't want the script to touch my MCP config? Register it by hand.</summary>

```bash
claude mcp add --scope user playwright -- npx -y @playwright/mcp@0.0.83
```
or edit `~/.claude.json`:
```jsonc
{ "mcpServers": { "playwright": { "type": "stdio",
  "command": "npx", "args": ["-y", "@playwright/mcp@0.0.83"] } } }
```
</details>

## Restart Claude Code

So the skill and MCP register. Verify with `/mcp` (playwright shows **Connected**)
and by typing `/qa-test` (the skill appears).

## Usage

```bash
cd path/to/any-app
claude
/qa-test '<feature or flow, optionally with a URL>'  [--headed]
```

- Runs **headless by default**. Add `--headed` (or `visual`) as a second arg to
  watch the run in a visible browser window — affects only this session, not the
  committed spec.

Examples:
```
/qa-test 'sign-up flow at /signup'
/qa-test 'sign-up flow at /signup' --headed                # visible browser
/qa-test 'CSV upload → aggregation report at /reports/new'
/qa-test 'checkout → Stripe → paid status'
```

**Auth flows:** never put secrets in a committed spec. Provide credentials via env
vars (`QA_TEST_EMAIL`, `QA_TEST_PASSWORD`, …) or a gitignored Playwright
`storage_state` file, and tell the skill which to use.

## Re-running later

A committed spec is a normal `pytest-playwright` test — re-run it with no AI, using
the dedicated runner:
```bash
~/.qa-test/venv/bin/pytest path/ --rootdir=path/ \
  --tracing=retain-on-failure --screenshot=only-on-failure
```
(`--rootdir` keeps pytest from importing the app's own `conftest.py`/plugins.)
Only invoke `/qa-test` again when the feature changes, or to triage a failure.

## Upgrading the Playwright MCP

`install.sh` registers one exact release, `PLAYWRIGHT_MCP_VERSION` at the top of the
script, never `@latest`. `@playwright/mcp` is pre-1.0 and each release bundles its own
Playwright alpha. An unpinned server would therefore change the browser the skill
drives on every machine whenever upstream publishes: its tools, its flags and its
accessibility snapshots.

To move to a newer release:

1. Read its release notes for renamed tools and changed flags. The skill drives the
   browser through them.
2. Try it on one machine: run `PLAYWRIGHT_MCP_VERSION=<new> ./install.sh`, restart
   Claude Code, and author one small flow with `/qa-test`.
3. Bump `PLAYWRIGHT_MCP_VERSION` in `install.sh` and the two commands above in this
   file. Everyone else picks it up on their next `./install.sh`, which moves the
   installer's own registration to the new pin.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `install.sh` warns "claude CLI not found" | Install Claude Code, then re-run `./install.sh` (or register the MCP by hand, see above). |
| `install.sh` warns "Node not found" | Install Node 18+; the Playwright MCP needs it. |
| `install.sh` warns it couldn't build the venv | Install Python 3 (and the `venv` module on Linux), check network, re-run `./install.sh`. |
| `/qa-test` not listed | Re-run `./install.sh`; restart Claude Code; check `~/.claude/skills/qa-test/SKILL.md` exists. |
| "Playwright MCP unavailable" | Re-run `./install.sh` (or add the server by hand) and restart Claude Code. |
| `~/.qa-test/venv/bin/pytest` missing | Re-run `./install.sh` — step 3 builds it. |
| Spec flaky on re-run | A fixed `sleep` or brittle selector slipped in — see `references/playwright-authoring.md` (wait on the observable signal). |
