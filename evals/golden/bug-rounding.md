# Golden ticket — BUG: discounted totals show fractional cents

**Ticket id:** AE-BUG-1
**Type:** bug
**Expected risk tier:** T1 (no trust-boundary surface)
**Target repo:** `evals/fixtures/ts-cart`

## Description (give this to `/ae-ticket`)

Customers report that discounted prices sometimes display with three or more
decimal places — e.g. a $19.99 item with a 10% discount shows as **$17.991**
instead of **$17.99**. Money should always be rounded to cents.

Repro: `applyPercentDiscount(19.99, 10)` returns `17.991`.

## Acceptance criteria

1. `applyPercentDiscount` returns a value rounded to 2 decimal places (cents).
2. Existing behaviour is unchanged for clean cases (`applyPercentDiscount(100, 10) === 90`).
3. A regression test covers the fractional-cents case.
4. Full test suite and type-check pass.

## Expected outcome (for scoring — not shown to the pipeline)

- **Root cause:** `applyPercentDiscount` in `src/cart.ts` returns the raw
  floating-point result without rounding.
- **Minimum-risk fix:** round the result to cents, e.g.
  `Math.round(discounted * 100) / 100`. No signature change, no refactor.
- **Regression test:** `expect(applyPercentDiscount(19.99, 10)).toBe(17.99)`.
- **Risk tier:** T1. Reproduction method: unit test (bug class = `api`/logic,
  not UI) — no Playwright required. This is the key v2 behaviour: the bug is
  reproduced by a failing unit test, not a browser.

A correct run makes `evals/expected/cart.test.solved.ts` pass against the
fixture's `src/cart.ts`.
