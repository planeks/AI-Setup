---
name: verify-change
description: Choose and run the narrowest sufficient checks for a change, then report honestly. Use before claiming a change works or is ready — after editing backend, frontend, or the API contract. Prefers focused checks over the full suite and never claims a command passed unless it actually ran.
---

# Verify change

Match the checks to what actually changed. Do not run the whole suite for a one-line edit; do not skip verification because a change "looks trivial".

## Lint/format vs tests

Lint and format are enforced by **pre-commit** (ruff, eslint, prettier — `.pre-commit-config.yaml`), so they run at commit time; run `pre-commit run --all-files` if you want them ahead of that. This skill and `scripts/check-changes.sh` are about the thing pre-commit deliberately doesn't do: **run the test suites**.

## Pick the scope

Look at `git status` / `git diff --name-only`:

- **Backend** (`src/**/*.py`, including `src/frontend/*.py` — the Django app) → `docker compose -f compose.dev.yml run --rm django test`.
- **Frontend** (`src/frontend/src/**`) → `docker compose -f compose.dev.yml exec -T frontend npm test`.
- **API contract** (`**/api/**`, serializers, views, urls) → also follow `api-contract-change` and regenerate the schema to review the diff.
- **Migrations added** → run `migrate` in a fresh container and confirm it applies clean.
- Docs / config-only changes → no tests; say so.

Containers must be up: `docker compose -f compose.dev.yml up -d`.

## Script

`scripts/check-changes.sh` derives scope from the git diff and runs the affected test suite(s) in Docker. It does not run lint/format — pre-commit owns those. It runs the whole suite for the affected side (backend or frontend), not per-app.

```bash
scripts/check-changes.sh              # test the working-tree diff
scripts/check-changes.sh --base main  # test everything since main
scripts/check-changes.sh --all        # backend + frontend suites
```

It prints exactly what it ran and what it skipped, and exits non-zero on any real failure. Read its final summary — do not infer a pass from the absence of red.

## Report honestly

- Never state a command passed unless you ran it and saw it pass. Quote the failing output when it fails.
- Distinguish **new** failures your change caused from **pre-existing** failures on the base branch (run the check on the base if unsure).
- Name what you could **not** verify (e.g. "did not run the frontend build", "no integration test for this path") — see `concise-engineering-output` for the closing format.
