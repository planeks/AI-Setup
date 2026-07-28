---
name: write-project-docs
description: Write natural engineering documentation — README, ADRs, architecture docs, runbooks, developer guides, PR descriptions, release notes, technical explanations. Use when producing prose meant for teammates. Sets voice and structure and strips LLM filler. Not for terse status output (see concise-engineering-output).
---

# Write project docs

Write as an experienced engineer for peers who will maintain this code. Docs live in `docs/` and render with MkDocs Material; `docs/code-quality.md` is the in-repo model for tone. See [references/style-examples.md](references/style-examples.md).

## Voice

- Lead with concrete facts and the commands/paths the reader needs. Do not restate the title in the first sentence.
- Short paragraphs. One idea each.
- State trade-offs and limitations directly — what this does not do, where it breaks down, what you would change under different constraints.
- Use this repo's terminology: `compose.dev.yml`, the entrypoint subcommands (`dev`, `test`, `manage`), `<app>/api/`, drf-spectacular, Vite manifest, Caddy, Celery/redbeat, MailHog, Flower.
- Do not invent motivation, requirements, benchmarks, incidents, or numbers. If a fact is not established, either find it or leave it out.
- No marketing language.

## Avoid LLM filler

Phrases like "robust and scalable", "seamless", "comprehensive", "leverage", "delve into", "it is important to note", "this ensures that", "in order to", "in today's fast-paced world", "key takeaways" almost always signal padding. This is guidance, not a blocklist — if one of these words is the precise term (e.g. `leverage` as financial leverage), use it. The goal is natural, specific, professional prose, not word-avoidance.

## Structure by document type

- **README / guides** — what it is, how to run it, where to go next. Command-first, second person, matches the existing docs.
- **ADR** — context, the decision, alternatives considered, consequences (including the downsides you accept). No repo has an ADR dir yet; if you start one, `docs/architecture/adr/NNNN-title.md`.
- **Runbook** — a symptom, then numbered steps with the exact commands, then how to confirm recovery. Written to be followed at 3am.
- **PR description** — what changed and why, how it was verified, and the risk/rollout. Reuse the `Changed / Verified / Risks / Not verified` shape from `concise-engineering-output`.
- **Release notes** — user-visible changes grouped by impact; call out breaking changes and migrations first.

Follow `CONTRIBUTING.md` conventions (Conventional Commits, branch prefixes) when the doc references process.
