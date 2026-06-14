---
name: bug-workflow
description: The Autonomous Engineer bug pipeline, tier-aware. The Orchestrator routes a bug through T0/T1/T2 depth and uses method-flexible reproduction (the evidence method fits the bug class). Composes from the six workflow patterns.
---

# Bug workflow (tier-aware)

The Orchestrator (main loop) drives this. Depth scales with the risk tier from `intake-analyst`.

## Pipeline by tier

**T0 — Trivial** (typo, copy, comment, config one-liner; blast radius none)
`software-engineer` (`bug`) → `reviewer` (`code`) → `engineering-manager`. No reproduction, no panel. Document the skip.

**T1 — Standard** (normal bug, no trust-boundary surface)
1. Intake — ready message, confirm. (`intake-analyst` ran for classification + tier + repo map.)
2. `qa-engineer` (`reproduce`) — method fits `bug_class` (ui→Playwright, api→test/call, data→query, build→command, timing→instrumented test). Verdict gate below.
3. `software-engineer` (`bug`) — root cause + corroborating evidence → Generate-and-Filter → minimum-risk fix + regression test.
4. `qa-engineer` (`validate`) — primary journey + edge cases + regression spot-checks.
5. `reviewer` ×2 in one response — `code` + the one risk lens that applies.
6. Loop-Until-Done (≤2). → `engineering-manager`.

**T2 — High-risk** (auth, sessions, payments, persistence/migrations, upload, external API, or production incident)
As T1 plus: Adversarial Verification on the root cause (spawn a second `software-engineer` to refute), and the **full reviewer panel** (`code`+`security`+`perf`+`arch`) in one parallel response. Loop ≤3. Security lens is mandatory.

## Verdict gate (reproduce + validate)
Only an evidenced verdict clears the phase. `not_reproduced` → comment the attempted journey on the ticket and ask the user for clearer steps; do **not** fix on assumption. `blocked` (missing env/fixture/test-mode) → Orchestrator escalates; never downgrade to "user verifies after merge". The gate is *reproduced/validated with evidence by the appropriate method* — not "via browser specifically".

## Parallelization map
| Phase | Mode |
|------|------|
| Intake (classify+tier+repo map) | one `intake-analyst` |
| Reproduce | sequential (`qa-engineer`) |
| Root cause | sequential; Adversarial = 2 parallel engineers (T2) |
| Implement | sequential |
| Validate | sequential |
| Reviewer panel | **parallel** — all required lenses in one response |
| Loop iteration | sequential outer; reviewer fan-out parallel inside |
| PR + close-out | sequential (`engineering-manager`) |

## Decision rules
- Skip reproduction only for T0, or when a verifiable failing test already pinpoints the assertion (still confirm it fails first).
- Skip reviewers only for T0; document it.
- Always include a regression test unless there's no test infra (then document manual verification).
- Root cause in a dependency → stop, open an upstream issue; workaround only if business-critical.
- Loop hits the cap → escalate, don't keep going.
