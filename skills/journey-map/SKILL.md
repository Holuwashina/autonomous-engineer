---
name: journey-map
description: The persistent user-journey registry — how a real user navigates each part of the system, with the inputs to use and the outputs to expect. QA reads it before testing so it never re-discovers navigation; QA and the engineer update it after every run so the system's test knowledge compounds. Read this whenever reproducing, validating, or building a feature that has a journey.
---

# Journey map — the system's persistent test knowledge

Without this, every QA run re-learns the app from scratch: where the login is,
how to reach the cart, what a valid payload looks like, what "success" looks like.
The **journey map** captures that once and keeps it, so each run *starts* from
known navigation + known inputs/outputs instead of figuring them out again. It is
the durable memory that makes every feature and fix repeatably testable.

## Where it lives

`.ae/journeys/` in the project root — one Markdown file per journey
(`.ae/journeys/<slug>.md`), plus `_template.md`. It persists across runs like
`.ae/resources.yaml`. By default it is **git-excluded** (local-only, AE's
zero-footprint rule). A team that wants to *share* the map can opt in by removing
`/.ae/journeys/` from `.git/info/exclude` and committing it — it's high-value test
documentation. That's a deliberate choice, never automatic.

Secrets never go in a journey. Reference an account by its `key` from
`.ae/resources.yaml` (e.g. `accounts.standard_user`), never an email+password.

## What one journey records

```markdown
# Journey: <name, e.g. "Apply a discount code at checkout">
Covers: <features / endpoints / ticket IDs this journey exercises>
Surface: ui | api | both
Persona: <account key from resources.yaml, e.g. accounts.standard_user | guest>
Entry: <UI path off base_url, or METHOD /endpoint>

## Preconditions / test data
- <what must exist first, and how to make it: declared fixture | create via the
  app's own flow (preferred) | seed script> — record the create path, not a value.

## Steps (the way a real user does it)
1. <action> — <stable landmark: role/label/test-id, or METHOD URL> — input: <value/shape>
2. ...
   (Prefer accessible/role-based or data-test selectors over brittle CSS/XPath.)

## Expected outcome (assertions)
- <observable result on the surface, or response status + shape>
- Edge / negative cases: <input → expected result>  (e.g. expired code → "Code expired", 422)

## Last verified
<YYYY-MM-DD> on <env> by run <run-id>. <one-line note on anything that changed.>
```

Keep steps **stable and selector-resilient**: anchor on roles, labels, and
`data-test` hooks, not pixel positions or auto-generated class names, so the
journey survives cosmetic UI churn.

## Protocol — read before, update after (both QA and engineer)

**Read first.** Before reproducing/validating (QA) or building a feature
(engineer), scan `.ae/journeys/` for a journey whose `Covers:` matches the ticket's
area. If one exists, **follow it** — its navigation, inputs, and expected outputs
are the starting point; don't re-derive them. If the app has changed and a step is
now wrong, follow the corrected path *and* fix the journey (see below).

**Update after — this is what makes it compound.** At hand-off:
- **New feature** → write a new `.ae/journeys/<slug>.md` from `_template.md`,
  capturing the real navigation, the inputs that work, and the expected outputs
  (happy + the edge cases you exercised). The engineer drafts the intended I/O; QA
  confirms/corrects it against the live run.
- **Bug fix** → ensure the affected journey exists and records the **regression
  path**: the input that used to break and the now-correct expected output.
- **Navigation/UI changed** → update the steps + selectors and bump `Last verified`.
- **Nothing changed** → just bump `Last verified` on the journey you used.

A journey is only trustworthy if it was *actually executed* this run — never write
"expected output" you didn't observe. Stale-but-honest beats confident-but-guessed;
mark uncertainty explicitly.

## How it feeds testability

The documented inputs/outputs are ready-made **test fixtures**: the engineer turns
each journey's happy + edge cases into automated tests at the right level (unit /
integration / component / contract), and QA's end-to-end run follows the same
journey. One source of truth for "what to send and what to expect" → features and
fixes are testable by construction, and the map gets richer with every ticket.
