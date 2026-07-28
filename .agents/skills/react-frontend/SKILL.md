---
name: react-frontend
description: Conventions for the React frontend in src/frontend — plain JavaScript/JSX (no TypeScript), Vite, Vitest + React Testing Library, i18next, Sentry, FontAwesome. Use when adding components, hooks, an API/data layer, forms, routing, or frontend tests. Not for backend or API-contract work (see django-backend, api-contract-change).
---

# React frontend

`src/frontend/` is a **plain JavaScript / JSX** app (no TypeScript, no `tsconfig`, no typecheck step). React 18 on Vite 5. It is currently a bare skeleton — treat the sections below marked **[when you add X]** as the agreed conventions for filling it in, not as existing code.

## What exists

- Entry: `src/index.jsx` mounts `<App/>` onto `#app-root` and imports the three setup modules.
- `src/App.jsx` — the single component.
- `src/setup/{i18n,icons,sentry}.js` — react-i18next, FontAwesome library registration, conditional Sentry init.
- `src/locales/en.json` — translations. `src/__tests__/` — Vitest setup + one test.
- Only these libraries are installed: `react`, `react-dom`, `react-i18next`, `@sentry/react`, `@fortawesome/*`. **Nothing else.**

## Django wiring (do not break)

Vite builds with `base: '/static/'` and `manifest: true`; entry `src/index.jsx`; output `dist/`. Django's `frontend/templatetags/vite_tags.py` reads the Vite manifest and injects the right `<script>`/`<link>` tags — dev loads from the Vite dev server (`:5173`), prod serves `dist/` via Caddy. Keep `src/index.jsx` as the single entry unless you also update `vite.config.js` and the template.

## Style (enforced)

- ESLint 9 flat config (`eslint.config.js`): `react` + `react-hooks` recommended, `react/react-in-jsx-scope` off (React 18 JSX transform), `react/prop-types` is a **warning** — document props.
- Prettier (`.prettierrc`): semicolons, **double quotes**, trailing commas `all`, `printWidth` 120, `tabWidth` 2.
- User-facing strings go through i18next (`useTranslation`), not hardcoded literals. Icons come from the registered FontAwesome library.

## Conventions for new code

- **[when you add features]** Group by feature: `src/features/<feature>/` holding its components, hooks, and tests together. Shared primitives in `src/components/`. Keep `App.jsx` as a thin composition/root.
- **[when you add an API layer]** No data layer exists and there is **no generated API client**. Add a small hand-written fetch wrapper under `src/api/` (attach the JWT `Authorization: Bearer` header, centralize the base URL and error handling). Backend auth is SimpleJWT — obtain tokens from `/api/token/`. Coordinate any endpoint change through `api-contract-change`.
- **Server vs local state** — no state library is installed. Use component state / hooks for local UI state. Do not add Redux, Zustand, Jotai, TanStack Query, or SWR without an explicit decision (they change the architecture). Same for `react-router`, a UI kit (MUI/Chakra/Ant/shadcn), a styling system (Tailwind/styled-components/CSS modules), or a form library (React Hook Form/Formik) + validation (zod/yup) — none are present; propose before pulling one in.
- **UI states** — every data-driven view handles loading, empty, error, and unauthorized explicitly. Do not render a bare spinner-forever on error.
- **Accessibility** — real semantic elements (`button`, `label`+`htmlFor`), keyboard reachable, `alt`/`aria-label` where needed.

## Testing

Vitest + React Testing Library (jsdom). Co-locate tests as `*.test.jsx` or under `__tests__/`. Query by role/text, mock Sentry and FontAwesome as the existing `App.test.jsx` does. Add a test with every component/behavior change.

## Verify

Containers up first (`docker compose -f compose.dev.yml up -d`).

```bash
docker compose -f compose.dev.yml exec frontend npm run lint
docker compose -f compose.dev.yml exec frontend npm run format:check
docker compose -f compose.dev.yml exec frontend npm test
```

Before a release-shaped change, confirm the production build: `docker compose -f compose.dev.yml exec frontend npm run build`.
