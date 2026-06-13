---
name: bug-workflow
description: The canonical Autonomous Engineer bug pipeline — from intake through reproduction, root cause, fix, validation, review, and PR. The Engineering Director composes this from the six workflow patterns.
---

# Bug workflow

The end-to-end pipeline for any ticket classified as a bug.

## Phases

### 1. Intake
- Director fetches the ticket via the ticket MCP (`ticket-protocol`).
- Director delivers the seven-section ready message.
- User confirms or redirects.

### 2. Classification
- If `/bug` forced the classification, skip. Otherwise invoke `technical-lead`.
- Output: `bug` + reasoning + reviewer-scope recommendation.

### 3. Repository mapping
- Invoke `solutions-architect`.
- Output: which repos are affected, cross-repo couplings, blast radius signals.

### 4. Environment selection
- Invoke `qa-environment-engineer` with `purpose=reproduce`.
- Output: environment / tenant / account selection.

### 5. Reproduction
- Invoke `qa-engineer` with `mode=reproduce`, passing the env-manager selection and the ticket's reproduction steps.
- Outcome:
  - `reproduced` → proceed to root cause.
  - `not_reproduced` → comment the attempted journey + evidence on the ticket; Director stops and asks user for clearer repro steps. **Do not proceed to fix code.**
  - `partially_reproduced` → document the actual symptom; Director decides whether to proceed as documented or escalate.
  - `blocked` → resolve the blocker (env, account, fixture) and retry.

#### Static-analysis substitute (rare)

Live reproduction is the **default**. A very small class of bugs can substitute static analysis:

- The reported symptom is a single wrong value visible in the diff (typo, wrong URL parameter, wrong constant, hard-coded string).
- The code change required is locally evident — no behaviour-graph reasoning, no concurrency, no state, no auth.
- The Validator (Phase 9) will still run a live Playwright journey post-fix; reproduction is being *deferred*, not skipped entirely.

When the Director judges these conditions are met, the substitution must be declared **in Section 5 (Plan) of the seven-section ready message**, with reasoning. Example:

> Plan: TL classify → Architect locate template → **skip live pre-fix reproduction (link-typo class, static analysis sufficient, Validator captures live post-fix evidence)** → Software Engineer applies + tests → Validator → reviewer panel.

The Director **may not** ask the user mid-run for permission to skip reproduction. If the option wasn't called out in the ready message, reproduction runs. Mid-run permission asks for a foreseeable choice indicate the ready message under-planned — escalate as "plan incomplete, re-running intake" instead.

### 6. Root cause + candidate fixes
- Invoke `software-engineer` with the reproduction report.
- The engineer:
  - Traces to root cause with corroborating evidence.
  - Generates candidate fixes (Generate-and-Filter).
  - Picks minimum-risk.

### 7. Adversarial verification (optional)
- For production-incident bugs, security-adjacent bugs, or fixes touching > the immediate symptom:
  - Spawn a second `software-engineer` instance prompted to refute the root cause.
  - If it can refute, return to step 6 with the new evidence.

### 8. Implementation
- Same `software-engineer` implements the chosen fix.
- Always includes a regression test.
- Runs the test suite; quotes results verbatim.

### 9. Validation
- Invoke `qa-environment-engineer` with `purpose=validate` (often a different environment than reproduction).
- Invoke `qa-engineer` with the validation plan derived from the reproduction:
  - Primary journey: the original repro should now succeed.
  - Edge cases: surrounding cases that could have been affected.
  - Regression spot-checks: adjacent flows.
- Invoke `qa-communications-engineer` if the journey touches communications.

### 10. Reviewer panel (Tournament)
- All four reviewers run in parallel: `code-reviewer`, `security-engineer`, `performance-engineer`, `software-architect`.
- Director collects all verdicts and findings.

### 11. Loop-Until-Done
- If any reviewer or the validator returns blocking findings:
  - Re-invoke `software-engineer` with the specific findings.
  - Re-run validator (full or targeted at the changed area).
  - Re-run reviewer panel.
- Stop conditions:
  - All reviewers approve **and** validator returns `pass` → proceed to PR.
  - 3 iterations without convergence → escalate to user.

### 12. PR + ticket close-out
- Invoke `engineering-manager`.
- It composes the PR title and body, pushes the branch, opens the PR (draft or ready per user instruction), and comments on the ticket with the PR link and evidence summary.
- It does **not** auto-merge or auto-transition status without strong project signals.

### 13. Director declares completion
- Final summary: PR URL, ticket URL, what was changed, what was validated, what reviewers approved, follow-ups identified, overall confidence.

---

## Parallelization Map

The Director must fan out concurrent specialists in a **single response** with multiple `Agent` tool calls. Default to parallel where the map allows.

| Phase | Mode | Specialists | Why |
|---|---|---|---|
| 1. Intake | SEQUENTIAL | (Director only) | One ticket fetch. |
| 2–3. Classification + Repo mapping | **PARALLEL** | `technical-lead` ‖ `solutions-architect` | Classification doesn't depend on the repo map; Architect doesn't need classification to enumerate repos. Fan out together at execution start. |
| 4. Env selection | SEQUENTIAL | `qa-environment-engineer` | Needs classification verdict. |
| 5. Reproduction | SEQUENTIAL | `qa-engineer` (`mode=reproduce`) (+ `qa-communications-engineer` only if email-touching) | Needs env. Comms only if journey involves a message — parallel with Reproducer when both are needed. |
| 6. Root cause | SEQUENTIAL | `software-engineer` | Needs reproduction evidence. |
| 7. Adversarial verification (optional) | **PARALLEL** | second `software-engineer` instance | Skeptic runs simultaneously with main engineer's confirmation pass; fanout of 2. |
| 8. Implementation | SEQUENTIAL | `software-engineer` | Single-engineer single-fix. |
| 9. Validation | SEQUENTIAL | `qa-engineer` (+ `qa-communications-engineer` only if email-touching) | Validator drives the journey end-to-end. Comms in parallel when applicable. |
| 10. Reviewer panel | **PARALLEL** | `code-reviewer` ‖ `security-engineer` ‖ `performance-engineer` ‖ `software-architect` | Independent perspectives. Always parallel — never serial. |
| 11. Loop iteration | SEQUENTIAL | implementer → validator → reviewers (panel still parallel inside) | Iteration is serial; the reviewer fan-out inside each iteration is parallel. |
| 12. PR + ticket close-out | SEQUENTIAL | `engineering-manager` | One agent, single push. |

**Multi-repo Architect note:** if the Solutions Architect needs to survey ≥2 repos, it should fan out its grep/Read work internally — but that's inside the Architect's run, not the Director's fan-out. The Director only sees one Architect agent.

**Logging the fanout:** before parallel specialists, emit a `[PARALLEL]` log line listing them:
```
[T] [PARALLEL] [classify] [director] Fanout: technical-lead || solutions-architect
```
After both return, log each return separately (with its `specialists/NN-<name>.json` reference). This makes the audit trail explicit about which work happened concurrently.

---

## Decision rules

- **Skip reproduction** only if the ticket includes a verifiable test failure with a clear path to the failing assertion. Even then, validate the failure manually before fixing.
- **Skip reviewers** only for trivial fixes (typo in user-facing string, comment). Document the skip.
- **Always include the security reviewer** for fixes touching auth, sessions, payments, persistence, file upload, external API, environment.
- **Always include a regression test** unless the codebase lacks any test infrastructure (then document the manual verification step).
- **Communications (email / OTP / magic-link / invite / push) are opt-in.** Invoke `qa-communications-engineer` and the configured email sink (maildrop / Mailtrap / etc.) **only when the bug's reproduction journey actually sends or depends on a message**. Bugs in unrelated surfaces (UI rendering, server errors, validation, etc.) do not trigger any comms call. If you find yourself about to poll an inbox for a bug that has nothing to do with email — stop.

## Common failure modes

- **Bug doesn't reproduce.** Don't fix code based on assumption. Push back to the user for clearer steps.
- **Root cause is in a dependency.** Stop. Open an upstream issue. Implement a workaround only if business-critical.
- **Fix passes tests but reviewer panel finds a security issue.** Iterate. Don't merge the fix and "follow up" on security separately.
- **Loop hits 3 iterations.** Escalate. Don't keep going.
