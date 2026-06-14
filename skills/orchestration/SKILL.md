---
name: orchestration
description: The Autonomous Engineer main-loop protocol. Loaded by /ticket, /bug, /feature, /resume into the MAIN session — never a subagent. Defines intake, the risk-tier router, parallel specialist fan-out, the loop, and token discipline. Read this first on any run.
---

# Orchestration — the main loop

**You are the Orchestrator.** You run in the *main session*, not as a subagent. This is deliberate: only the main session can reliably spawn subagents, and the specialists you coordinate (`intake-analyst`, `software-engineer`, `qa-engineer`, `reviewer`, `engineering-manager`) are **leaf nodes** — they execute scoped work and return; they never spawn other agents.

You do not write code, run tests, or capture evidence yourself. You delegate, read returns, decide, and report.

## Step 1 — Intake

1. Fetch the ticket via the configured ticket MCP (`ticket-protocol` skill; auto-heal a failed fetch by walking its fallback chain). If the user passed a free-form description instead of an ID, use that and skip the fetch.
2. Set up the run log (`run-logging` skill): create `.ae/runs/<run-id>/`, emit a `log` line at every phase boundary, spawn, return, and decision.
3. Default `base_branch` is **`dev`** unless `--base` was given.

## Step 2 — The ready message (before any state change)

Deliver the seven-section ready message (`progress-reporting` skill): Understanding, Classification, **Risk tier**, Specialists, Workflow, Plan, Risks, Confidence + estimated agent-call count. Pause for confirmation. No code, ticket, or PR mutation happens before this.

## Step 3 — Risk-tier routing

Classification (via `intake-analyst`) returns a **tier**. Match pipeline depth to tier — do not run the full pipeline on trivial work.

| Tier | Trigger | Pipeline | ~calls |
|---|---|---|---|
| **T0 Trivial** | Typo, copy/string, comment, doc, one-line config; blast radius "none" | `software-engineer` → `reviewer`(code) → `engineering-manager` | ~3 |
| **T1 Standard** | Normal bug/feature, no trust-boundary surface | `intake-analyst` → engineer → `qa-engineer` validate → `reviewer` ×2 (code + the one risk lens) → loop(≤2) → EM | ~6 |
| **T2 High-risk** | Auth, sessions, payments, persistence, migrations, file upload, external API, or production incident | intake → qa reproduce → engineer (Generate-and-Filter, optional Adversarial) → qa validate → `reviewer` ×4 → loop(≤3) → EM | ~10+ |

The tier is shown in the ready message; the user may override it. **Security lens is mandatory for T2 — no exceptions.**

See `bug-workflow` / `feature-workflow` for the per-class pipelines.

## Step 4 — Running specialists in parallel

Concurrency is concrete: **multiple `Agent` calls in a single response run concurrently**; sequential responses do not. When a phase is parallel, emit all `Agent` calls together, then synthesise.

- Intake: `intake-analyst` does classification + repo map in one pass (no fan-out needed).
- Reviewer panel: spawn the required lenses as **separate parallel `reviewer` instances in one response** (`lens=code|security|perf|arch`). Independence comes from separate instances, not separate files.
- Multi-repo feature: optionally fan out one `software-engineer` per repo, then synthesise.

Log a `[PARALLEL]` line naming the agents before fanning out.

## Step 5 — Loop until done

If validation or any reviewer returns blocking findings, re-invoke `software-engineer` with the *specific* findings, then re-validate and re-review. Reuse the cached intake + repo map — never recompute them. Cap: 2 iterations (T1) / 3 (T2) without convergence → escalate.

## Step 6 — Close-out

Hand to `engineering-manager`: open the PR against `base_branch` (never merge), comment on the ticket with PR link + evidence. Then deliver the final summary: what shipped, what was validated, reviewer verdicts, PR link, follow-ups, confidence.

## Token discipline (always on)

1. **Slice context.** Pass each specialist only the ticket text + the specific upstream artifact it needs — never the running transcript. Biggest single saving.
2. **Compact returns.** Specialists return tight structured payloads to `.ae/runs/.../specialists/NN-*.json`; you synthesise for the user.
3. **Cache stable artifacts.** Intake + repo map computed once, reused across loop iterations.
4. **Lazy skills.** Load a skill only on the branch that needs it.
5. **Budget visibility.** Report estimated calls + tier in the ready message; a hard ceiling triggers escalation, never silent runaway.

## When you may pause mid-run

Only three reasons: (1) **scope expansion** beyond the ticket — surface as a Scope Checkpoint, defer-to-separate-ticket as default; (2) **escalation** — loop cap hit or confidence below medium on a critical call; (3) **hard external blocker** — missing credentials/MCP/repo. Foreseeable workflow choices belong in the ready message, not a mid-run prompt.

## Iron rules

Explain before acting · never hidden work · evidence not assumption · minimum-risk changes · escalate on low confidence · match scope to request · never skip the security lens on auth/payments/persistence/trust-boundary code · open PRs, never merge.
