---
name: context-efficient-work
description: Gather only the context a change needs — spend fewer tokens and reads before editing. Use at the start of a task and whenever you are about to open more files. Favors symbol search, ranged reads, and the repo map over reading whole files or scanning generated trees.
---

# Context-efficient work

Read to find the edit boundary, then stop. More context is not more correct.

## Rules

1. Start from the task scope, `git status`, and [docs/architecture/repository-map.md](../../../docs/architecture/repository-map.md). Open the nearest relevant directory, not the tree.
2. Search for symbols and the nearest similar implementation first (grep for a class/function/endpoint name) before reading files top to bottom.
3. Read specific line ranges, not whole large files. Widen only when the range is not enough.
4. Never recursively scan generated or vendored trees: `node_modules/`, `.venv/`, `src/frontend/dist/`, `migrations/` data, `data/`, `docs/site` build output, `poetry.lock`/`package-lock.json` in full.
5. Read the public contract before the implementation: a serializer/view signature and `api/router.py` before the body; a component's props before its internals.
6. Stop collecting context once the change's boundaries are clear. If you can name the files to edit and the checks to run, begin.
7. Do not re-open unchanged files without a new reason. Trust what you already read this session.
8. Use the repo's own docs (`docs/`, `CONTRIBUTING.md`, `code-quality.md`, the repository map) instead of reconstructing architecture by reading source.
9. Reach for external docs only for unfamiliar, recently-changed, or version-sensitive APIs — and check the installed version first (`src/pyproject.toml`, `src/frontend/package.json`).
10. When you do need a library API, request the one specific symbol/topic — do not pull in broad library documentation for a single call.

## This repo's fast paths

- Backend routes: `src/config/urls.py` → `<app>/urls.py` → `<app>/api/router.py`.
- A worked API example (view + serializer + task + JWT + schema annotations): `src/accounts/api/`.
- Commands: `docs/code-quality.md`. Architecture at a glance: the C4 diagram in `docs/index.md`.
- Frontend entry and Django wiring: `src/frontend/src/index.jsx`, `src/frontend/templatetags/vite_tags.py`.
