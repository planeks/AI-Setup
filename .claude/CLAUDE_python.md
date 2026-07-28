# CLAUDE.md — Python (PLANEKS)

> Layer this on top of [`CLAUDE_base.md`](./CLAUDE_base.md). Framework files (Django/Flask/FastAPI) layer on top of this.

---

## Style & formatting

- **PEP 8** is the baseline. Use the official Python style guide for anything not specified here.
- **Casing:**
  - `snake_case` — variables, functions, methods, modules, packages
  - `CapitalizedWords` (PascalCase) — classes, exceptions
  - `UPPER_SNAKE_CASE` — constants
  - `_leading_underscore` — internal/private; `__double_leading` — name-mangled (avoid unless you know why)
- **Tools (run before commit):**
  - `flake8` — linting
  - `isort` — import ordering
  - Configure both in `pyproject.toml` or `setup.cfg`. Match the team's existing config.
- Line length 120 chars (override PEP 8's 79).

## Imports

- Order via `isort`: stdlib → third-party → first-party → local relative.
- Prefer absolute imports inside packages. Avoid `from module import *`.
- No unused imports — `flake8` will catch them.

## Type hints

- Use type hints on public functions/methods and on anything non-trivial.
- For complex types: `from typing import ...` or PEP 604 (`X | None`) on Python 3.10+.
- Run `mypy` if the project has it configured. Don't add it unilaterally — coordinate with the team.

## Docstrings

- Every public function, class, and module gets a docstring.
- Use **Google** or **NumPy** style — pick one and stick to it project-wide.
- Cover: purpose, args, returns, raises, side effects.

```python
def calculate_total_price(items: list[Item], discount: float = 0.0) -> Decimal:
    """Calculate cart total after applying a discount.

    Args:
        items: Cart items to total.
        discount: Fractional discount (0.0–1.0).

    Returns:
        Final price as Decimal.

    Raises:
        ValueError: If discount is outside [0, 1].
    """
```

## Error handling

- **No bare `except`.** Always catch specific exception types.
- Log the exception with context. Use `logger.exception(...)` inside `except` to capture the traceback.
- Don't use exceptions for control flow if a conditional works.
- Define custom exception classes for domain-specific errors. Inherit from a base project exception.

## Logging

- Use the stdlib `logging` module. Get a logger via `logger = logging.getLogger(__name__)`.
- Never `print()` for production code. `print` is for one-off scripts only.
- Don't log secrets, tokens, PII, or raw request bodies that may contain them.

## Dependencies & environments

- Pin dependencies. Use `requirements.txt` + `requirements-dev.txt`, or `pyproject.toml` with **Poetry** / **uv** / **pip-tools** — match the project's choice.
- **Never** commit `venv/`, `.env`, `*.pyc`, or build artifacts.
- One virtual env per project. Document the Python version in README.

## Configuration

- All config via environment variables. Use `python-dotenv` or `pydantic-settings` to load.
- Never hardcode URLs, secrets, API keys.
- Provide `.env.example` with placeholder values committed to the repo.

## Testing

- Default framework: **pytest** (preferred) or **unittest**.
- Test layout: `tests/` mirrors the package structure, or `test_*.py` next to source — match project convention.
- Aim for high coverage on business logic and edge cases. Use `pytest-cov` to track.
- Fixtures via `conftest.py`. Parametrize with `@pytest.mark.parametrize`.
- Mock external services (HTTP, DB, queues) with `unittest.mock` or `pytest-mock`. Use `responses` / `httpretty` / `respx` for HTTP.
- Keep tests fast and deterministic. Mark slow/integration tests with custom markers.

## Concurrency

- Choose deliberately: threads for I/O-bound + blocking libs, `asyncio` for I/O-bound + async libs, `multiprocessing` for CPU-bound.
- Don't mix `asyncio` and blocking I/O inside the same coroutine without `run_in_executor`.

## Performance

- Profile before optimizing (`cProfile`, `py-spy`, `line_profiler`).
- Database queries are usually the bottleneck — see framework-specific files for ORM N+1 guidance.
- Prefer generators / iterators over building large lists in memory.

## Security

- Validate and sanitize all external input.
- SQL: parameterized queries only — never f-string SQL. ORMs handle this.
- Passwords: hash with `bcrypt` / `argon2` (via `passlib` or framework auth). Never store plaintext.
- Secrets: env vars only. Use a secrets manager (AWS Secrets Manager / Vault) in production.
- Dependencies: run `pip-audit` before adding or upgrading deps; CI runs it on PRs.

## Project structure (typical)

```
project/
├── src/<package>/        # or just <package>/
│   ├── __init__.py
│   ├── domain/           # business logic, framework-agnostic
│   ├── infrastructure/   # DB, external services
│   ├── api/              # HTTP layer (framework-specific)
│   └── settings.py
├── tests/
├── scripts/              # one-offs, migrations helpers
├── .env.example
├── pyproject.toml
└── README.md
```

- Framework-specific layouts override this in their CLAUDE.md.

---

## Common pitfalls

- Mutable default args: `def f(x=[])` — use `None` and create inside.
- Catching `Exception` to hide real bugs.
- `os.path` instead of `pathlib.Path` for new code.
- Manual JSON parsing without validating shape — use Pydantic / dataclasses.
- Forgetting context managers (`with`) — file handles, DB sessions, locks leak otherwise.
