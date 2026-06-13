---
name: feature-workflow
description: The canonical Autonomous Engineer feature pipeline — from intake through planning, implementation, validation, review, and PR. Used for any ticket classified as feature or enhancement.
---

# Feature workflow

The end-to-end pipeline for any ticket classified as `feature` or `enhancement`.

## Phases

### 1. Intake
- Director fetches the ticket via the ticket MCP (`ticket-protocol`).
- Director delivers the seven-section ready message.
- User confirms or redirects.

### 2. Classification
- If `/feature` forced it, skip. Otherwise invoke `technical-lead`.
- Output: `feature` (or `enhancement`) + reasoning + reviewer-scope recommendation.

### 3. Repository mapping
- Invoke `solutions-architect`.
- Output: which repos are affected, cross-repo couplings, blast radius signals.

### 4. Feature planning
- Invoke `product-engineer`.
- Output: acceptance criteria, users/journeys, data model changes, API surface, UI surface, dependencies, ordered implementation steps, validation plan.

If the Product Engineer flags that acceptance criteria were derived (not explicit in the ticket), the Director pauses and asks the user to confirm before implementation begins.

### 5. Implementation
- Invoke `software-engineer` with `mode=feature` and the plan.
- The engineer executes step-by-step:
  - Branch off `base_branch`.
  - For each step: read affected files → modify → write tests → run tests → commit.
  - Reuse existing primitives (don't invent parallels).
  - Run full test suite at the end.
  - Self-review the diff.

### 6. Environment selection for validation
- Invoke `qa-environment-engineer` with `purpose=validate`.
- Output: environment / tenant(s) / account(s) for the validation pass.

### 7. Validation
- Invoke `qa-engineer` with the plan's validation strategy:
  - Primary journey per acceptance criterion.
  - Edge cases per the plan.
  - Cross-role / cross-tenant checks (use `multi-tenant` for multi-tenant apps).
- Invoke `qa-communications-engineer` if the feature touches email / OTP / magic-link / invitation / push.

### 8. Reviewer panel (Tournament)
- All four reviewers in parallel: `code-reviewer`, `security-engineer`, `performance-engineer`, `software-architect`.
- For auth / payments / persistence / trust-boundary features, the full panel is mandatory.

### 9. Loop-Until-Done
- If any reviewer or the validator returns blocking findings:
  - Re-invoke `software-engineer` (still `mode=feature`) with the specific findings.
  - Re-run validator (full or targeted).
  - Re-run reviewer panel.
- Stop conditions:
  - All reviewers approve **and** validator returns `pass` → proceed to PR.
  - 3 iterations without convergence → escalate to user.

### 10. PR + ticket close-out
- Invoke `engineering-manager`.
- It composes title/body (acceptance criteria checklist in the body), pushes the branch, opens the PR, comments on the ticket.

### 11. Director declares completion
- Final summary: PR URL, ticket URL, what was built, acceptance criteria coverage, validation evidence, reviewer verdicts, follow-ups, overall confidence.

---

## Parallelization Map

The Director must fan out concurrent specialists in a **single response** with multiple `Agent` tool calls. Default to parallel where the map allows.

| Phase | Mode | Specialists | Why |
|---|---|---|---|
| 1. Intake | SEQUENTIAL | (Director only) | One ticket fetch. |
| 2–3. Classification + Repo mapping | **PARALLEL** | `technical-lead` ‖ `solutions-architect` | Independent; fan out at execution start. |
| 4. Feature planning | SEQUENTIAL | `product-engineer` | Needs classification verdict and repo map. |
| 5. Implementation | SEQUENTIAL | `software-engineer` (`mode=feature`) | Single coherent diff, one engineer. |
| 6. Env selection for validation | SEQUENTIAL | `qa-environment-engineer` | Needs implementation complete. |
| 7. Validation | SEQUENTIAL | `qa-engineer` (+ `qa-communications-engineer` in **parallel** when the feature acceptance criteria reference a message) | Validator drives the journey; Comms runs alongside if the journey involves email/OTP/links. |
| 8. Reviewer panel | **PARALLEL** | `code-reviewer` ‖ `security-engineer` ‖ `performance-engineer` ‖ `software-architect` | Independent perspectives. Always parallel — never serial. |
| 9. Loop iteration | SEQUENTIAL | implementer → validator → reviewers (panel still parallel inside) | Iteration is serial; the reviewer fan-out inside each iteration is parallel. |
| 10. PR + ticket close-out | SEQUENTIAL | `engineering-manager` | One agent, single push. |

**Multi-repo plan note:** if the Product Engineer's plan touches ≥2 repos with independent work streams, the Director may fan out parallel `software-engineer` (`mode=feature`) instances per repo at Phase 5 — but only when the streams have no shared types or contracts that need to land first. When in doubt, serialize.

**Logging the fanout:** before parallel specialists, emit a `[PARALLEL]` log line listing them:
```
[T] [PARALLEL] [classify] [director] Fanout: technical-lead || solutions-architect
```
After both return, log each return separately (with its `specialists/NN-<name>.json` reference). This makes the audit trail explicit about which work happened concurrently.

---

## Decision rules

- **Acceptance criteria must be explicit.** If derived from the description, confirm with the user before implementing.
- **Always plan migrations as discrete steps** ahead of code that depends on them.
- **Always reuse existing primitives.** The Product Engineer names them; the Software Engineer uses them.
- **Always validate cross-role / cross-tenant** in multi-tenant codebases when the feature touches authorization or visible UI.
- **Always run the full reviewer panel** for auth, payments, persistence, trust boundaries, public API additions.
- **Communications (email / OTP / magic-link / invite / push) are opt-in.** Invoke `qa-communications-engineer` and the configured email sink (maildrop / Mailtrap / etc.) **only when the feature's acceptance criteria reference a message** (e.g. "user receives a verification email"). Features in unrelated surfaces (reports, dashboards, settings UI, internal APIs) do not trigger any comms call.

## Common failure modes

- **Plan ambiguity reaches implementation.** If the implementer needs to "decide" something the plan didn't decide, that's a planning failure. Report it to the Director — don't decide unilaterally.
- **Feature flag forgotten.** If the plan called for a flag and the implementer skipped it, the validator catches it (the feature shouldn't be live without the flag in a canary).
- **Acceptance criterion declared "covered" without a test.** Block. Either add the test or document the manual verification step.
- **Loop hits 3 iterations.** Escalate.
