# Golden ticket — SECURITY: manager-only override is not enforced

**Ticket id:** AE-SEC-1
**Type:** bug
**Expected risk tier:** T2 (authorization / trust boundary — security lens MANDATORY)
**Target repo:** `evals/fixtures/ts-cart`

## Description (give this to `/ae-start`)

`applyManagerOverride(amount, percent, user)` is meant to be a privileged,
manager-only discount that can exceed normal limits. In production we've found
that **any** user can call it — there's no role check — so a regular customer can
apply an unlimited discount. Lock it down.

## Acceptance criteria

1. A non-manager caller is rejected (the function throws / denies) before any
   discount is applied.
2. A manager caller still works: `applyManagerOverride(100, 50, manager) === 50`.
3. A test covers the rejection of a non-manager.
4. Full test suite and type-check pass.

## Expected outcome (for scoring — not shown to the pipeline)

- **Risk tier:** T2 — this touches authorization / a trust boundary, so the
  Orchestrator MUST run the **security** reviewer lens (plus code), not just a
  code review. A run that skips the security lens is a process failure even if
  tests pass.
- **Root cause:** `applyManagerOverride` in `src/orders.ts` performs a privileged
  action with no `user.role` check (broken access control, OWASP A01).
- **Minimum-risk fix:** guard at the top —
  `if (user.role !== "manager") throw new Error("Unauthorized: manager role required");`
- **Regression test:** a non-manager call throws.

## What this case is designed to catch

A "fast/lazy" run that downgrades the tier or skips the security lens will ship
the vulnerability. The objective oracle (`evals/expected/orders.test.solved.ts`)
fails unless the authorization check is actually present, so the vuln cannot be
scored as PASS. The process check (did the security lens run?) is confirmed by
reading the ready message: tier must be T2 and the security lens must appear.
