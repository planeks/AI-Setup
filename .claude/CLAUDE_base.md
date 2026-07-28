# CLAUDE.md — PLANEKS Base Standards

> **Scope:** Code-level standards Claude must apply when writing or editing code in any PLANEKS project. Layer framework-specific files (Python/Django/Flask/FastAPI/React) on top.
>
> Human-level policy (client reporting, hosting choices, backups, on-call, etc.) lives in the team wiki, not here — it doesn't change what Claude writes.

---

## Language & naming

- **English only.** All names of files, variables, functions, parameters, classes, methods, comments, data structures, DB fields/tables, branches, commit messages, and code documentation must be English. No exceptions.
- Descriptive and meaningful names. Prefer short over long, but never sacrifice readability.
  - Good: `calculate_total_price`. Bad: `calc_price`.
- Language-specific casing rules live in framework files.

## Code formatting

- **Max line length: 120 chars.**
- Consistent indentation, spacing, and bracket placement.
- Always run the project's configured linter/formatter before completing a task. Match the existing config (`pyproject.toml`, `.eslintrc`, etc.) — never override it ad-hoc.
- Don't bypass pre-commit hooks (no `--no-verify`). If a hook fails, fix the underlying issue.

## Comments

- Document **why**, not how. The code shows how; the comment explains intent or a non-obvious constraint.
- No emotional commentary, jokes, or remarks about previous code quality.
- Split long functions (50+ lines) into smaller blocks with intent comments per block where helpful.
- When deviating from a standard (PEP 8, naming, etc.) — leave a one-line comment with the reason.
- When using code/algorithm from an external source (GitHub gist, article), add a reference comment.
- `# TODO:` for temporary or simplified solutions that need revisiting. Don't leave silent shortcuts.

## Docstrings

- Every public function, class, and module gets a docstring.
- Cover purpose, args, returns, raises (or framework equivalent). Style is set per project — match what's already in the file.

## Project docs alongside code

When a change affects setup, public API, or architecture:

- Update the README (setup instructions, env vars, new commands, new dependencies).
- Update API docs (OpenAPI annotations, GraphQL schema descriptions, generated reference).
- For significant architectural changes, add or update an ADR if the project keeps them.
- Doc updates go in the **same commit/PR** as the code change — never "I'll do it later."

## Error handling

- Catch **specific** exception types. No bare `except` / `catch (Throwable)`.
- Log with context (`logger.exception(...)` inside `except` to capture the traceback).
- Don't suppress exceptions to make tests pass or "stabilize" a path. Fix the root cause.

```python
try:
    value = dictionary['key']
except KeyError as e:
    logger.error(f"KeyError: {e}")
```

## Git

When Claude creates branches or commits via `git` / `gh`:

- **Branches:** `feature/<short-desc>`, `fix/<short-desc>`, `hotfix/<short-desc>`. Include the Jira/Trello ticket tag if there is one. Keep names short.
- **Commits:** atomic — one logical change per commit. Conventional format, ≤ 72 chars for the subject:
  - `feat: Add new authentication method`
  - `fix: Handle null user in profile view`
- **Pull requests** (when created via `gh pr create`):
  - **Title:** the conventional commit subject.
  - **Body:** 1–3 bullet summary of what changed, link to the Trello/Jira ticket if there is one, brief test plan.
  - If the reviewer can't access the ticket tracker, put a short summary in the body instead of just the link.
- **Never commit:** compiled artifacts, third-party libs (use the project's package manager), commented-out "dead" code, `.env`, secrets.

## Testing

- Write/update tests for every code change. Cover the happy path, the obvious edge cases, and any branch you just added.
- Test framework, layout, and runner are defined per project — match what exists. Don't introduce a new test framework unilaterally.
- Mock external services (HTTP, queues, third-party APIs) in unit tests. Use the project's existing mocking conventions.

## Secrets & configuration

- **No hardcoded secrets, API keys, URLs, or passwords.** Read them from environment variables (`os.environ`, `import.meta.env`, etc.).
- If `.env.example` exists, add a placeholder line there for every new env var you introduce.
- Passwords are hashed with bcrypt / argon2 via the framework's recommended lib — never stored in plaintext.

## Security defaults (code-level)

Apply these whenever Claude touches the relevant code paths:

- **SQL:** parameterized queries / ORM only. Never f-string SQL.
- **Output:** rely on the template engine's auto-escape. Use `|safe` / `dangerouslySetInnerHTML` only on content you've verified.
- **HTTP input:** validate at the boundary (serializers / schemas). Don't trust client data.
- **CSRF:** keep it on for cookie-based sessions; not needed for stateless tokens in `Authorization` headers.
- **File uploads:** validate type and size; store outside the app process (cloud storage), not on local disk.
- **CORS:** never combine `allow_origins=["*"]` with `allow_credentials=True`.
- **Dependencies:** if a new package is requested, prefer the project's existing patterns (e.g. `django-anymail` for email, `django-axes` for brute-force protection) over inventing wiring from scratch.

## When in doubt

1. **Read the existing code first.** Match the conventions you find — even if your preference differs.
2. **Don't bypass safety checks** (pre-commit, linter, tests, CI) to move faster. Diagnose and fix.
3. **Don't add abstractions for hypothetical future needs.** Solve the task in front of you.
4. **State assumptions in PR descriptions** when Claude generates them, so reviewers can challenge them.
