# AGENTS.md — frontend (`src/frontend/`)

React/Vite rules. Adds to the root and `src/` `AGENTS.md`. Full standards:
`.claude/CLAUDE_react.md` — but read the deviations below first, because several of its
defaults do not apply here.

## This directory is two things at once

A **Django app** (`views.py`, `templatetags/`, `templates/frontend/index.html`) *and* the
**Vite project** (`package.json`, `vite.config.js`, `src/`).

Assets reach the browser through `{% vite_asset 'src/index.jsx' %}` — the tag reads
`dist/.vite/manifest.json` in production and points at the dev server in development. Vite's
`base` is `/static/` on build so Whitenoise/Caddy serve the hashed files.

So: **never hardcode `/static/` or `dist/` paths in a template, and never add a second
static-asset pipeline.** Browser-visible env vars must be prefixed `VITE_`
(`VITE_SENTRY_DSN`, `VITE_DEV_SERVER_HOST`).

## Deviations from `.claude/CLAUDE_react.md` — this repo wins

| Template says | Here | Why |
|---|---|---|
| TypeScript, strict mode | **plain JSX**, no TS | the boilerplate ships JS — don't migrate a project unilaterally, propose it |
| `eslint-config-airbnb` | ESLint 9 flat config: `js.recommended` + `react` + `react-hooks` | airbnb has no stable flat-config build |
| feature-first `src/features/<x>/` | flat `src/` (`App.jsx`, `setup/`, `locales/`) | the starter is tiny — **adopt feature-first as soon as a second feature appears** |
| TanStack Query / RTK Query, react-hook-form, zod, React Router | none installed | add one only when there's a real need, not preemptively |

Installed and expected to be used: `react-i18next` (strings go in `src/locales/`, not inline),
`@sentry/react`, FontAwesome. Setup lives in `src/setup/{sentry,i18n,icons}.js`.

## Commands

```bash
RUN="docker compose -f compose.dev.yml exec frontend"
$RUN npm run lint          # and lint:fix
$RUN npm run format        # prettier write; format:check to verify
$RUN npm test              # vitest run; test:watch to iterate
$RUN npm run build         # → dist/ + .vite/manifest.json
$RUN npm install <pkg>     # then rebuild the image
```

Commit `package.json` **and** `package-lock.json`.

## Code

Functional components and hooks only. PascalCase component files, `use*` hooks, props
destructured in the signature. `prop-types` is a lint warning here (no TS to lean on) — declare
them on shared components.

`useEffect` is for synchronising with external systems, not for deriving state — compute during
render. Keep the dependency array honest; don't disable `exhaustive-deps`. Clean up
subscriptions and timers.

Every async surface has loading, error and empty states. Semantic HTML before ARIA; labels on
form fields; keyboard reachable.

## Tests

Vitest + Testing Library + jsdom; setup in `src/__tests__/setup.js`, example in
`src/__tests__/App.test.jsx`. Query by role and label, not by class or test id. Test behaviour,
not implementation — no snapshot-only tests.
