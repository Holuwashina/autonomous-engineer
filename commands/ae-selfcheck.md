---
description: Run the Autonomous Engineer self-check — drive the golden tickets through the pipeline against the bundled fixture repo and score the result objectively.
argument-hint: "[bug|feature|security|all]"
---

You are the Autonomous Engineer. The user invoked `/ae-selfcheck $ARGUMENTS`.

This is the project's own end-to-end eval. It proves the pipeline actually runs
and produces correct results, and it makes prompt changes measurable.

Scope: `bug` (AE-BUG-1, T1), `feature` (AE-FEAT-1, T1), `security` (AE-SEC-1, T2),
or `all` (default).

The `security` ticket is the important one: it's a broken-access-control bug, so
the ready message MUST classify it **T2** and run the **security** reviewer lens.
A run that downgrades the tier or skips the security lens is a failure even if the
suite goes green — confirm the tier and lens in the ready message, not just the
score. The objective oracle (`evals/expected/orders.test.solved.ts`) only passes
if the authorization check is actually implemented.

Process:

1. **Confirm the fixture baseline.** Run:
   `sh evals/run-selfcheck.sh baseline`
   Expect 2 passing tests (the rounding bug is latent). If it isn't green, stop
   and report — the fixture is dirty; `sh evals/run-selfcheck.sh reset` restores it.

2. **Run each selected golden ticket through the real pipeline.** For each, read
   the ticket body from `evals/golden/<file>.md` and become the Orchestrator
   (load the `orchestration` skill), targeting the fixture repo
   `evals/fixtures/ts-cart` with `--base dev`. Treat the ticket Description as a
   free-form ticket (no ticket MCP needed). Run the full tier-appropriate
   pipeline: intake → (reproduce for the bug, plan for the feature) → implement
   with a regression/feature test → validate by running the suite → reviewer
   lens(es) → loop if needed. Do not open a real PR — stop at a clean branch.
   Reproduction/validation method is **unit tests** (bug class = logic), not a
   browser — this is the v2 method-flexible gate.

3. **Score objectively.** Run it with the SAME scope you ran, so it only checks
   the oracle(s) for the tickets you actually ran:
   `sh evals/run-selfcheck.sh score <scope>`  (scope = `security` | `bug` | `feature` | `all`)
   It checks: the pipeline's own tests pass, type-check passes, the scope's golden
   acceptance oracle passes against the implementation, and the pipeline added at
   least one of its own tests. Report the `SELFCHECK: PASS/FAIL` line plus the
   per-ticket agent-call count you observed (token-budget signal).

4. **Reset for next time:** `sh evals/run-selfcheck.sh reset`.

Report a short table: ticket → tier → result → agent calls. This is a regression
gate: run it before and after any change to the agents/skills/commands.
