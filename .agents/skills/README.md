# Agent Skills

Project-level skills that encode this repo's conventions for AI coding agents. Written to be tool-agnostic — plain Markdown, no Claude-only hooks, subagents, or slash commands.

## Layout

- `.agents/skills/` — **canonical source.** Edit skills here.
- `.claude/skills/` — relative symlinks into this directory so Claude Code auto-discovers them. Do not edit there; they point back to these files.

OpenAI Codex and other agents read the skills from `.agents/skills/` directly (see `AGENTS.md`).

Each skill is a directory with a `SKILL.md` (YAML frontmatter: `name`, `description`, then the body). Some carry a `references/` folder for depth kept out of the main file (progressive disclosure).

## Skills

| Skill | Use when |
|-------|----------|
| `django-backend` | Editing backend Python — models, migrations, serializers, views, permissions, Celery, tests |
| `react-frontend` | Editing the React/JSX frontend — components, hooks, API layer, forms, tests |
| `api-contract-change` | A change is observable across the DRF/API boundary |
| `verify-change` | Choosing and running the narrowest sufficient checks before claiming done |
| `write-project-docs` | Writing README/ADR/architecture/runbook/PR prose |
| `context-efficient-work` | Gathering only the context a change needs |
| `concise-engineering-output` | Reporting work to engineers — lead with the conclusion |
| `systematic-debugging` | Diagnosing a bug rather than guessing a patch |

## Maintenance

If a skill and the code disagree, the code wins — update the skill. When conventions here change (a service layer is added, the frontend gains an API client or router), revise the affected skill in the same PR.
