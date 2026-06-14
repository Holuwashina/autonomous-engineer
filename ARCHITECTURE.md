# Autonomous Engineer — Architecture & Redesign

**Goal:** professional, fast, low-token — without losing the quality bar that makes the system worth using.

**Design principle:** quality comes from *independent perspectives and evidence*, not from *headcount*. We keep every review lens and every evidence gate, but we stop paying for them on tickets that don't need them, and we stop re-loading context that hasn't changed.

---

## 1. The one change that makes everything else work

Today `/ae-start` invokes the **Engineering Director as a subagent**, and the Director is expected to spawn 12 more subagents (including parallel fan-outs). In Claude Code, **a subagent generally cannot spawn its own subagents** — only the top-level session can. As written, the Director cannot call `Agent` at all, so the whole orchestration silently fails or degrades into the Director doing everything itself in one context (the opposite of the design).

**Fix:** the Orchestrator becomes the **main session loop**, not a subagent.

- `/ae-start` no longer hands off to a `engineering-director` subagent. Instead it loads the orchestration protocol **into the main loop** (via a skill the command reads, e.g. `orchestration`).
- The main loop is the only thing that spawns specialists. Specialists are **leaf nodes** — they never spawn other agents.
- This is also faster and cheaper: we remove one full agent-context hop (the Director's own subagent context) from every single run.

This must be proven before anything else ships. Acceptance test: from a `/ae-start` run, confirm the main loop successfully spawns two specialists *in parallel in one response* and reads both returns.

---

## 2. Roster: 13 → 1 orchestrator + 5 specialists

The 13-agent roster has real redundancy: three QA agents that share context, four reviewer files that are 80% identical, and intake split across two cheap agents. We consolidate where it's pure overhead and **keep separation only where it buys independence or safety**.

| v2 role | Replaces | Why |
|---|---|---|
| **Orchestrator** (main loop) | engineering-director | Runs the show; only node that delegates. Not a subagent (see §1). |
| **Intake Analyst** | technical-lead + solutions-architect | Classification and repo-mapping are both cheap read-only passes with no dependency between them — one agent, one context load does both. |
| **Software Engineer** (modes: `plan`, `bug`, `feature`) | software-engineer + product-engineer | Feature planning becomes a `plan` mode with an explicit checkpoint, so design-before-build is preserved without a second context hop. Heavy features can still split (see note). |
| **QA Engineer** (modes: `reproduce`, `validate`; reads resources; handles comms inline) | qa-engineer + qa-environment-engineer + qa-communications-engineer | One QA context that selects its own environment and checks email/OTP only when the journey touches it. The 3-way split was the clearest over-decomposition. |
| **Reviewer** (lens param: `code` \| `security` \| `perf` \| `arch`) | code-reviewer + security-engineer + performance-engineer + software-architect | **Independence comes from running separate parallel instances, not separate files.** One maintainable prompt, spawned up to 4× in a single response. Same rigor, a quarter of the prompt surface to maintain and drift. |
| **Engineering Manager** | engineering-manager | PR + ticket close-out. Unchanged. |

**Quality safeguard:** the Reviewer consolidation does **not** reduce review coverage. On high-risk tickets all four lenses still run as four independent parallel instances — they just share one well-tested prompt definition instead of four divergent ones.

**Escape hatch:** for genuinely large multi-repo features, the Orchestrator may still fan out multiple Software Engineer instances (one per repo) and synthesize — that capability stays.

Net: **5 agent definition files** to maintain instead of 13, and fewer context hops per run.

---

## 3. Adaptive routing — pay for rigor only when it's needed

The current bug pipeline runs ~10 phases on *every* bug, including mandatory live Playwright repro and a full 4-reviewer panel. That is the speed and token killer. v2 routes by a **risk tier** decided at intake.

| Tier | Trigger | Pipeline | Approx. agent calls |
|---|---|---|---|
| **T0 — Trivial** | Typo, copy/string, comment, doc, single-line config; blast radius "none" | Orchestrator → Engineer → 1 Reviewer (code lens) → EM | ~3 |
| **T1 — Standard** | Normal bug/feature, no trust-boundary surface | Intake → Engineer → QA `validate` → 2 lenses (code + the one risk lens that applies) → loop (cap 2) → EM | ~6 |
| **T2 — High-risk** | Touches auth, sessions, payments, persistence, migrations, file upload, external API, or a production incident | Full pipeline: Intake → QA `reproduce` → Engineer (Generate-and-Filter) → optional Adversarial → QA `validate` → **all 4 lenses** → loop (cap 3) → EM | ~10+ |

The tier is declared in the ready message so the user sees (and can override) the chosen depth. **Security lens is non-negotiable for T2** — same iron rule as today.

---

## 4. Evidence gates: keep them strict, make the *method* fit

Today: *"Live Playwright reproduction is mandatory for every bug class. There is no static-analysis substitute."* This dead-ends every backend, data, race-condition, build, or non-UI bug.

v2 keeps the principle — **no fixing on assumption; every bug is reproduced by appropriate means** — but the method matches the bug class:

| Bug class | Reproduction method |
|---|---|
| UI / user journey | Playwright (+ DevTools when the failure isn't visible) |
| API / backend logic | Failing API call or integration test |
| Data / state | Query or fixture that demonstrates the bad state |
| Build / CI / tooling | The failing command, output quoted |
| Race / timing | Targeted test or instrumented log capture |

The quality gate is *"reproduced, with evidence"* — not *"reproduced via browser."* This removes the biggest source of false `blocked` escalations while keeping the anti-assumption discipline intact.

---

## 5. Token discipline (the part that's currently unmanaged)

These are the concrete levers, in order of payoff:

1. **Context slicing.** The Orchestrator passes each specialist *only* the artifact it needs (the ticket text + the specific upstream output), never the running transcript. This is the single biggest token win.
2. **Compact structured returns.** Specialists return tight JSON to the Orchestrator's `.ae/runs/.../specialists/NN-*.json`, not prose essays. The Orchestrator synthesizes for the user.
3. **Cache the stable artifacts.** Intake + repo map are computed once and *reused* across loop iterations — never recomputed on iteration 2/3.
4. **Lazy skill loading.** Agents read a skill only on the branch that needs it. No preloading all 10 skills.
5. **Prompt diet.** Every agent file capped at ~120 lines; remove the duplicated blocks and verbose restatements. Shorter prompts = better instruction-following *and* fewer input tokens per spawn.
6. **Loop cap 2 for T1, 3 for T2.** Most runs converge on iteration 1; the third pass rarely changes the outcome and doubles cost.
7. **Per-run budget in the ready message.** Report an estimated agent-call count and tier so cost is visible up front, and add a hard ceiling that triggers escalation rather than silent runaway.

---

## 6. Professionalism: make it measurable and consistent

- **Eval harness (new).** A `/ae-selfcheck` command runs 3–5 golden tickets against a fixture repo and reports pass/fail + agent-call count. Nothing ships to the agent/skill files without a green selfcheck. This is what turns prompt edits from guesswork into engineering.
- **Fix the concrete defects found in v1:**
  - `engineering-director.md` — the *"When you may pause for the user mid-run"* block is duplicated verbatim. Remove one copy.
  - **Default base branch is inconsistent three ways:** `ticket.md`→`dev`, `engineering-director.md`→`main`, `software-engineer.md`→`dev`. Standardize on **`dev`** everywhere (matches the command and the engineer).
- **Versioning.** Add a `CHANGELOG.md` and a version in `plugin.json`; bump on every roster/pipeline change.
- **Memory at the orchestration layer.** Let the Orchestrator keep lightweight project memory (recurring tiers, flaky journeys, repo quirks) so routing improves run-over-run — today only reviewers/QA have memory.

---

## 7. Migration plan (incremental, each step shippable)

1. **Prove §1** — convert `/ae-start` to drive the main loop; verify parallel spawn + dual return from a real run. *(Blocking gate — nothing else proceeds until green.)*
2. **Land the eval harness** (§6) with the current behavior as the baseline, so every later step is measured against it.
3. **Consolidate the Reviewer** (4 files → 1 lens-parameterized agent); confirm 4 parallel instances still run on a T2 ticket.
4. **Consolidate QA** (3 → 1 with modes); confirm env-selection and comms-on-demand still work.
5. **Merge Intake** (2 → 1) and fold feature planning into the Engineer's `plan` mode.
6. **Add adaptive routing tiers** (§3) and **method-flexible gates** (§4).
7. **Apply token discipline** (§5) and the prompt diet.
8. **Fix the concrete defects** (§6) — can be done anytime, cheap.

Each step keeps the system runnable and is independently revertable.

---

## 8. Before / after at a glance

| | v1 (today) | v2 (proposed) |
|---|---|---|
| Orchestrator | Subagent (likely can't delegate) | Main loop (delegates reliably) |
| Agent definition files | 13 | 5 + orchestration skill |
| Bug pipeline depth | ~10 phases, always | 3 / 6 / 10 by risk tier |
| Reproduction | Playwright mandatory, all bugs | Method fits bug class, always evidenced |
| Review independence | 4 separate files | 4 parallel instances, 1 prompt |
| Context passed to specialists | Unspecified | Sliced to the needed artifact |
| Cost visibility | None | Tier + estimated calls in ready message |
| Correctness measurement | None | `/ae-selfcheck` golden tickets |
| Known defects | dup block, 3-way branch mismatch | fixed |

**Bottom line:** same quality gates, far less waste. The headline wins are (1) an orchestrator that actually works, (2) rigor that scales with risk instead of running flat-out every time, and (3) measurable correctness so the system can be improved with evidence instead of vibes.
