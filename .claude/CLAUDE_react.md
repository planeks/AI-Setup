# CLAUDE.md — React (PLANEKS)

> Layered on top of [`CLAUDE_base.md`](./CLAUDE_base.md).

---

## Stack defaults

- **Language:** TypeScript (preferred over plain JS). Strict mode on.
- **Build tool:** Vite (preferred for new projects). Next.js if SSR/SSG is needed. CRA only for legacy.
- **Styling:** project's choice — Tailwind, CSS Modules, styled-components, or SCSS. Pick one and stick to it.
- **HTTP client:** `fetch` + a thin wrapper, or **TanStack Query** / **RTK Query** for server state.
- **Forms:** **react-hook-form** + **zod** for validation.
- **Routing:** **React Router** (SPA) or Next.js routing.
- **Testing:** **Vitest** (or Jest) + **React Testing Library**, **Cypress** / **Playwright** for E2E.

## Style guide

- **Airbnb JavaScript Style Guide** + standard React rules (per PLANEKS base standards).
- **Lint:** ESLint with `eslint-config-airbnb` (or `@typescript-eslint` + `eslint-plugin-react` + `eslint-plugin-react-hooks`).
- **Format:** Prettier. Pre-commit hook (`lint-staged` + `husky`).
- Don't disable rules ad-hoc — discuss in the team if a rule fights the codebase.

## Naming

- Components: **PascalCase** files and exports: `UserCard.tsx` exports `UserCard`.
- Hooks: `use*` camelCase: `useUserProfile`.
- Variables/functions: camelCase.
- Constants: `UPPER_SNAKE_CASE`.
- Types/interfaces: PascalCase. Don't prefix interfaces with `I` (TypeScript convention).
- Booleans: `isLoading`, `hasError`, `canSubmit`.

## Project structure

```
src/
├── app/                       # app shell, providers, routing
├── pages/ or routes/          # route-level components
├── features/<feature>/        # feature-scoped: components, hooks, api, store
│   ├── components/
│   ├── hooks/
│   ├── api.ts
│   └── types.ts
├── components/                # shared UI primitives
├── hooks/                     # shared hooks
├── lib/                       # third-party wrappers, helpers
├── store/                     # global state (Redux/Zustand)
├── styles/
├── types/                     # global types
└── main.tsx
```

- **Feature-first** layout for medium+ apps. `src/components` is for genuinely shared primitives, not a dumping ground.
- Co-locate tests next to source: `UserCard.test.tsx` next to `UserCard.tsx`.

## Components

- **Functional components + hooks only.** No class components in new code.
- One component per file (unless tightly coupled and private).
- Keep components small. If a component does too much → extract custom hooks for logic, child components for UI.
- Props typed with TypeScript interfaces. Destructure props in the signature.
- Don't mutate props or state directly — always produce new references.

```tsx
interface UserCardProps {
  user: User;
  onEdit?: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <article>
      <h3>{user.name}</h3>
      {onEdit && <button onClick={() => onEdit(user.id)}>Edit</button>}
    </article>
  );
}
```

## Hooks

- Follow the rules of hooks: call at the top level only, never in conditionals/loops.
- Custom hooks for reusable logic, not just for "moving code out of a component."
- `useEffect` is for **synchronizing with external systems**. For derived state, compute during render or use `useMemo`.
- Always provide the dependency array. Let `eslint-plugin-react-hooks` guard it — don't disable the rule.
- Cleanup side effects (subscriptions, timers, listeners) in the returned function.

## State management

- **Local state** (`useState`, `useReducer`) by default.
- **Context** for cross-cutting *low-frequency* state (theme, auth, locale). Don't use Context as a global store — it re-renders all consumers.
- **Server state**: **TanStack Query** or **RTK Query** — handles caching, dedup, retries, invalidation.
- **Client global state**: **Redux Toolkit** (large/team projects), **Zustand** (smaller/simpler).
- Don't put server data in Redux unless you have a clear reason — let TanStack Query own it.

## Data fetching

- Centralize API calls in a `features/<x>/api.ts` module. Components call hooks, hooks call API functions.
- Handle loading, error, and empty states explicitly — every async UI has at least three states.
- Cancel in-flight requests on unmount (TanStack Query handles this; if using raw fetch, use `AbortController`).
- Don't fetch inside `useEffect` if a data-fetching lib is available — use that lib.

## Forms

- **react-hook-form** + **zod** for schemas. One schema = validation + TypeScript types.
- Controlled vs uncontrolled: prefer uncontrolled with `react-hook-form` for performance.
- Disable submit while pending. Show field-level errors inline.
- Re-validate on blur and submit, not on every keystroke (unless UX demands).

## Performance

- Profile before optimizing — React DevTools Profiler.
- `useMemo` / `useCallback` for expensive computations or referential equality across renders. Don't sprinkle them defensively.
- `React.memo` for components that re-render often with the same props.
- Lazy-load route components with `React.lazy` + `Suspense`.
- Virtualize long lists (`react-window`, `@tanstack/react-virtual`).
- Image optimization: lazy-loading, responsive `srcset`, WebP/AVIF.

## Accessibility

- Semantic HTML first (`button`, `nav`, `main`, `article`). ARIA only when semantic HTML can't express the intent.
- Every interactive element is keyboard-navigable and focus-visible.
- Form fields have labels (`<label htmlFor>` or `aria-label`).
- Images have meaningful `alt` (or `alt=""` for decorative).
- Color contrast meets WCAG AA.

## Cross-browser & responsive

- Test on the project's supported browsers (define in `package.json` `browserslist`).
- Mobile-first CSS.
- Avoid hover-only interactions for primary actions — touch devices don't have hover.

## Testing

- **Unit / component tests:** Vitest + React Testing Library. Test behavior, not implementation.
  - Query by accessible role/text (`getByRole`, `getByLabelText`), not by class/id.
  - No snapshot-only tests — they catch nothing useful.
- **Integration:** mount the feature, mock the API (MSW), assert user flows.
- **E2E:** Cypress or Playwright for golden-path flows.
- Mock HTTP with **MSW** — works in tests and in dev.

## Error handling

- **Error boundaries** around route trees and async UI sections.
- Show a fallback UI; log to Sentry.
- Never `try/catch` to suppress errors silently.
- Server errors → map to user-friendly messages; show details only in dev.

## TypeScript

- Strict mode on (`strict: true` in tsconfig).
- Prefer `type` for unions/intersections, `interface` for object contracts that may be extended.
- Avoid `any`. Use `unknown` + narrowing when shape is uncertain.
- No `// @ts-ignore` without a comment explaining why and a TODO.

## Routing

- Route-level code splitting: lazy-load page components.
- Protect routes with a wrapper component (`<RequireAuth>`).
- Don't read auth state inside every page — read once at the route boundary.

## Configuration

- All env vars go through Vite's `import.meta.env.VITE_*` (or `process.env.NEXT_PUBLIC_*` for Next.js).
- Never put secrets in client code — anything shipped to the browser is public.
- Separate configs per environment (`.env.development`, `.env.production`).

## Security

- Sanitize HTML if you must render it — **DOMPurify**. Avoid `dangerouslySetInnerHTML`.
- Validate URLs before opening (no `javascript:` URLs).
- Store auth tokens carefully: HttpOnly cookies (preferred) > sessionStorage > localStorage (avoid for tokens if XSS is a concern).
- CSP headers (server-side) to limit attack surface.

## Build output

- Cache-bust via hashed filenames (Vite does this automatically). `index.html` short cache, assets long.
- Source maps in production: upload to Sentry but don't serve publicly.

---

## Anti-patterns

- Class components in new code.
- `useEffect` to derive state — compute it during render.
- Putting all state in Redux because "global is easier."
- `any` in TypeScript to silence the compiler.
- Fetching in `useEffect` without cleanup → stale state and warnings on unmount.
- Inline functions/objects in JSX as `React.memo` props (breaks memoization).
- `key={index}` on dynamic lists (breaks reconciliation when items reorder).
- Putting business logic in components — extract to hooks or plain functions.
- Disabling `eslint-plugin-react-hooks/exhaustive-deps` ad-hoc.
