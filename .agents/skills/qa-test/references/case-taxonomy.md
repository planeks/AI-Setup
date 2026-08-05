# QA case taxonomy

Code tells you which cases are *reachable*. It will not volunteer the cases that
matter most — the ones a careful human QA adds from experience. Walk this list
for every feature and keep the ones that apply. Each kept case becomes one entry
in the plan and one test in the spec.

## 1. Happy path(s)
The intended success flow(s), end to end, with realistic valid input. If the
feature has distinct successful variants (e.g. signup with vs. without an invite
code), each is its own happy path.

## 2. Input validation & boundaries
For every field discovered in the code:
- required vs. optional (submit with it empty);
- format rules (bad email, weak password, wrong file type);
- boundaries (min/max length, 0, negative, very large, just over/under a limit);
- whitespace-only, leading/trailing spaces, unicode/emoji, very long strings;
- mismatch pairs (password vs. confirm-password).
Assert the **intended** validation message/behavior (oracle), not whatever string
the code currently emits.

## 3. Empty / loading / error states
- empty state (no data yet — first run, empty list);
- loading state (does a spinner/skeleton appear; is the control disabled while
  in flight);
- server/validation error surfaced to the user (the app's error UI, not a stack
  trace);
- offline / failed request handling if the app claims to handle it.

## 4. Async-chain end-states  ← the differentiator
For each backend chain you traced (upload→job→result, action→webhook→status,
etc.): assert the **user-observable end-state** and wait on the observable signal.
See [observable-end-states.md](observable-end-states.md). Use deterministic
fixtures so expected numbers/statuses are fixed.

## 5. Auth & permission variants
- logged-out user hitting a protected route (redirect to login? returns after?);
- wrong role / insufficient permission (hidden vs. blocked vs. 403 page);
- session expiry mid-flow if relevant.
Pull credentials from env or a gitignored `storage_state` — never hard-code.

## 6. Navigation & lifecycle
- browser **back** after submit; **refresh** mid-flow (state preserved or lost as
  intended);
- **deep-link** straight to a later step (guarded or broken?);
- **double-submit** / rapid double-click (idempotent? duplicate created?);
- dead ends, broken links, redirect loops;
- multi-step wizards: leaving and returning, skipping a step.

## 7. Concurrency / repeat
- re-running the same action (does it duplicate? is it idempotent?);
- two tabs / stale data (optional, if the feature implies it).

## 8. Responsive / visual sanity (only if relevant)
- mobile viewport: does the critical control remain reachable;
- obvious layout breakage on small screens.
Keep this light unless the feature is explicitly responsive — the accessibility
tree covers most authoring needs; deep visual diffing is a separate add-on.

## 9. Data variation — one case per representative input  ← big-feature fan-out
When the feature ingests files/records and the user points at a directory of
examples (importers, parsers, AI extractors):
- treat **each distinct file/format as its own case** — don't test one file and
  call it covered. **Parametrize over the fixture directory** (see the snippet in
  [playwright-authoring.md](playwright-authoring.md)).
- cover the spread the examples represent: different exporters/layouts, large vs.
  tiny, complete vs. **partial** (missing required columns/fields), empty,
  duplicate, and malformed/garbage.
- assert the **observable end-state per file** (e.g. "Imported N expense(s)" with N
  fixed by that fixture), not a generic "no error".

## 10. Conversational / multi-turn correction loops  ← AI & wizard flows
Flows that pause to ask the user for missing or ambiguous data (AI clarification
chats, "we couldn't read the vendor — which property?", multi-step wizards that
branch on input) are **real cases, each with its own oracle**:
- **happy branch** — complete input, no questions asked, flows straight to finalize;
- **missing-field branch** — incomplete input → the UI **surfaces the question** →
  you answer → the flow **resumes and finalizes** (assert the question appears AND
  the post-answer end-state);
- **ambiguous branch** — input matches several options → correct disambiguation UI;
- **rejected branch** — input the system can't use → clear, visible refusal, no
  partial/garbage import.
Drive the whole conversation as the user would; assert each turn's observable
result, not the model's internal text.

## Prioritize
Tag each case `high | medium | low`:
- **high** — happy path + each async-chain end-state + auth gate + each headline
  data-variation/conversational branch. These must pass (or be verified live + gated
  with that called out).
- **medium** — validation, error states, key navigation, secondary file formats.
- **low** — exotic boundaries, responsive sanity.
Call out high/medium failures prominently in the report; mention low failures too.
For a big feature, list **every** branch (incl. deferred/gated ones) — never let one
quietly disappear.
