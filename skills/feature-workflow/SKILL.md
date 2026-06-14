---
name: feature-workflow
description: The Autonomous Engineer feature/enhancement pipeline, tier-aware. The Orchestrator routes by risk tier and folds planning into the Software Engineer's `plan` mode. Composes from the six workflow patterns.
---

# Feature workflow (tier-aware)

The Orchestrator (main loop) drives this for `feature` and `enhancement` tickets. Depth scales with the risk tier from `intake-analyst`.

## Pipeline by tier

**T0 — Trivial** (one-line/copy-level addition)
`software-engineer` (`feature`) → `reviewer` (`code`) → `engineering-manager`.

**T1 — Standard**
1. Intake — ready message, confirm. (`intake-analyst` gave classification + tier + repo map.)
2. `software-engineer` (`plan`) — acceptance criteria + ordered, testable plan. Ambiguous criteria are flagged to the Orchestrator, not invented.
3. `software-engineer` (`feature`) — execute the plan, tests alongside code, contracts maintained across layers.
4. `qa-engineer` (`validate`) — acceptance journeys + edge cases + regression spot-checks; comms checks only if the journey sends a message.
5. `reviewer` ×2 in one response — `code` + the one risk lens that applies.
6. Loop-Until-Done (≤2). → `engineering-manager`.

**T2 — High-risk** (auth/payments/persistence/migrations/upload/external-API surface)
As T1 plus the **full reviewer panel** (`code`+`security`+`perf`+`arch`) in one parallel response; loop ≤3; security lens mandatory.

**Multi-repo features:** the Orchestrator may fan out one `software-engineer` (`feature`) per repo in a single response, then synthesise — Fanout-and-Synthesize. Only when the streams share no types/contracts that must land first; when in doubt, serialize.

## Verdict gate (validate)
Only an evidenced verdict clears validation. `blocked` (env shortfall, missing fixture/test-mode trigger) → Orchestrator escalates; never downgrade to "user verifies after merge". Passing unit/integration tests are necessary but not sufficient — the acceptance journey must be exercised by the method appropriate to the feature.

## Parallelization map
| Phase | Mode |
|------|------|
| Intake | one `intake-analyst` |
| Plan | sequential (`software-engineer` `plan`) |
| Implement | sequential; per-repo fan-out parallel for multi-repo |
| Validate | sequential |
| Reviewer panel | **parallel** — required lenses in one response |
| Loop iteration | sequential outer; reviewer fan-out parallel inside |
| PR + close-out | sequential |

Log a `[PARALLEL]` line naming the agents before any fan-out, and log each return with its `specialists/NN-*.json` reference.

## Decision rules
- Always derive acceptance criteria before building; a criterion without a test (or documented manual step) is not "done". If criteria are derived rather than explicit, confirm with the user before implementing.
- Plan migrations as discrete steps ahead of dependent code.
- Feature flags default off unless the plan says otherwise.
- New dependencies must be flagged in the plan, never introduced silently.
- Reuse existing primitives; the reviewer `arch` lens checks for parallel implementations.
- Full reviewer panel is mandatory for auth/payments/persistence/trust-boundary/public-API features regardless of perceived risk.
