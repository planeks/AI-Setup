# In-repo style examples

The best-written doc in this repo is `docs/code-quality.md`. Match its register.

## What it does well

- **Opens with a fact, not a preamble.** First line states what the doc covers and moves on — no "In this document we will explore...".
- **Command-first.** Almost every section ends in a fenced block the reader can run, e.g. the backend lint block:
  ```bash
  docker compose -f compose.dev.yml exec django ruff check .
  ```
- **Names the tool and where its config lives**, e.g. "Ruff handles both linting and formatting. Configuration lives in `src/pyproject.toml`." Concrete file, concrete responsibility.
- **Short declarative sentences.** One tool, one job, one location per sentence.

## Tutorial docs

`docs/local_setup.md` is the more hand-holding register: second person, `$`-prefixed shell blocks, occasional emoji section headers (🐳, 🔨). Use that voice for setup/onboarding guides; use the tighter `code-quality.md` voice for reference docs, ADRs, and runbooks.

## Do not

- Copy large sections of existing docs into new ones — link to them (README already does this).
- Add a "Conclusion" / "Key takeaways" section to a reference doc.
- Describe the stack as "robust", "scalable", or "seamless" — describe what it is and what it costs.
