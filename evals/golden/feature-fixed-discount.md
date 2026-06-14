# Golden ticket — FEATURE: fixed-amount discounts

**Ticket id:** AE-FEAT-1
**Type:** feature
**Expected risk tier:** T1
**Target repo:** `evals/fixtures/ts-cart`

## Description (give this to `/ticket`)

Today the cart only supports percentage discounts. Add support for a
**fixed-dollar** discount — e.g. "$15 off" — as a new function
`applyFixedDiscount(amount, off)`.

## Acceptance criteria

1. `applyFixedDiscount(amount, off)` subtracts a fixed dollar amount:
   `applyFixedDiscount(50, 15) === 35`.
2. It never returns a negative total — it caps at 0:
   `applyFixedDiscount(10, 15) === 0`.
3. The result is rounded to cents.
4. Tests cover the happy path, the cap-at-zero case, and rounding.
5. Full test suite and type-check pass.

## Expected outcome (for scoring — not shown to the pipeline)

- **Plan:** new exported function in `src/cart.ts`; no change to existing
  functions; tests added alongside.
- **Implementation:**
  `const d = Math.max(0, amount - off); return Math.round(d * 100) / 100;`
- **Risk tier:** T1. Validation method: unit tests. No new dependencies.

A correct run makes `evals/expected/cart.test.solved.ts` pass against the
fixture's `src/cart.ts`.
