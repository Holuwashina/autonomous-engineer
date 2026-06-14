# Autonomous Engineer — Evals (`/ae-selfcheck`)

This is the project's own regression gate. It exists so the system is **proven to
run** and so any change to the agents/skills/commands is **measurable** instead of
guessed. Run it before and after editing anything.

## Layout

```
evals/
├── fixtures/ts-cart/        # a real Node+TS pricing library (the repo under test)
│   ├── src/cart.ts          # ships WITH a planted rounding bug + a missing feature
│   └── src/cart.test.ts     # green baseline (2 tests) that hides the bug
├── golden/
│   ├── bug-rounding.md            # AE-BUG-1 (T1) — bug ticket + expected outcome
│   ├── feature-fixed-discount.md  # AE-FEAT-1 (T1) — feature ticket + expected outcome
│   └── security-override.md       # AE-SEC-1 (T2) — access-control bug; security lens MANDATORY
├── expected/
│   ├── cart.solved.ts / cart.test.solved.ts      # reference + acceptance oracle (T1)
│   └── orders.solved.ts / orders.test.solved.ts  # reference + acceptance oracle (T2)
└── run-selfcheck.sh          # baseline | score | reset
```

## How scoring works

The golden acceptance spec (`expected/cart.test.solved.ts`) is the oracle. A
correct pipeline run leaves `fixtures/ts-cart/src/cart.ts` satisfying that spec.
`run-selfcheck.sh score` reports PASS only when all four hold: the pipeline's own
tests pass, type-check passes, the golden spec passes against the implementation,
and the pipeline added at least one test of its own.

## What has been verified here (captured evidence)

**1. Nested delegation — the core v2 assumption.** A subagent was spawned and
asked to spawn a child agent. It reported it has **no subagent-spawning tool**
("Edit, Glob, Grep, Read, … none of which spawn a child agent"). This confirms
only the main session can delegate — which is exactly why v2 makes the
Orchestrator the main loop and treats specialists as leaf nodes. The v1 design
(Director-as-subagent spawning subagents) could not have worked.

**2. The bug pipeline produces a correct fix (real red→green).**
- Baseline: `Tests: 2 passed, 2 total` (bug latent).
- Added regression test `applyPercentDiscount(19.99, 10) === 17.99` → **red**:
  `Expected: 17.99 / Received: 17.991` (the planted bug).
- Applied minimum-risk fix (`Math.round(discounted * 100) / 100`) → **green**:
  `Tests: 3 passed`, `tsc --noEmit` clean.

**3. The feature pipeline produces a correct implementation.**
- Added `applyFixedDiscount(amount, off)` (caps at 0, rounds to cents) with three
  tests (happy path, cap-at-zero, rounding) → `Tests: 6 passed, 6 total`,
  type-check clean.

**4. The T2 security case produces a correct fix (real red→green).**
- `applyManagerOverride` ships with no role check — any user can apply it
  (broken access control, OWASP A01). Baseline suite is green (happy path only).
- Added the authorization regression test → **red**:
  `expect(() => applyManagerOverride(100, 50, user)).toThrow()` →
  `Received function did not throw` (the live vulnerability).
- Added the role guard (`if (user.role !== "manager") throw …`) → **green**:
  `Tests: 4 passed`, type-check clean.
- This case is designed so a run that downgrades the tier or skips the security
  lens still ships the hole; the oracle (`expected/orders.test.solved.ts`) only
  passes when the check is actually present.

**5. The scorer discriminates.** On the unsolved fixture → `SELFCHECK: FAIL`
(golden acceptance FAIL). On the fully-solved fixture (both T1 and T2) →
`SELFCHECK: PASS`. Fixture then reset to the 3-test green baseline.

## The one step that must run inside Claude Code

Everything above validates the **logic** and the **harness**. The remaining proof
— that Claude Code actually drives the `/ae-start` main-loop and spawns the
specialist subagents — can only be done where the slash commands and agents are
installed. Two minutes:

```bash
# 1. From the repo root, confirm the fixture baseline:
sh evals/run-selfcheck.sh baseline          # expect: 3 passing tests

# 2. In Claude Code, with this project installed, run the eval:
/ae-selfcheck all
#   (or run the tickets manually:)
#   /ae-start "$(cat evals/golden/bug-rounding.md)" --base dev
#   /ae-start "$(cat evals/golden/feature-fixed-discount.md)" --base dev
#   /ae-start "$(cat evals/golden/security-override.md)" --base dev   # T2 — watch for the security lens

# 3. Score and reset:
sh evals/run-selfcheck.sh score             # expect: SELFCHECK: PASS
sh evals/run-selfcheck.sh reset
```

Watch for, during the run: the ready message names a **risk tier** (both tickets
should be T1); the bug is reproduced by a **unit test**, not a browser
(method-flexible gate); reviewer runs the **code lens** (T1) and not the full
panel; and the agent-call count lands near the orchestration skill's estimate
(~6 for T1). Those are the v2 behaviours this eval is designed to confirm.
