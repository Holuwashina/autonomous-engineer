---
name: cceo-bug-workflow
description: The canonical CCEO bug pipeline — from intake through reproduction, root cause, fix, validation, review, and PR. The Engineering Director composes this from the six workflow patterns.
---

# Bug workflow

The end-to-end pipeline for any ticket classified as a bug.

## Phases

### 1. Intake
- Director fetches the ticket via the ticket MCP (`cceo-ticket-protocol`).
- Director delivers the seven-section ready message.
- User confirms or redirects.

### 2. Classification
- If `/bug` forced the classification, skip. Otherwise invoke `cceo-technical-lead`.
- Output: `bug` + reasoning + reviewer-scope recommendation.

### 3. Repository mapping
- Invoke `cceo-solutions-architect`.
- Output: which repos are affected, cross-repo couplings, blast radius signals.

### 4. Environment selection
- Invoke `cceo-qa-env-manager` with `purpose=reproduce`.
- Output: environment / tenant / account selection.

### 5. Reproduction
- Invoke `cceo-qa-reproducer` with the env-manager selection and the ticket's reproduction steps.
- Outcome:
  - `reproduced` → proceed to root cause.
  - `not_reproduced` → comment the attempted journey + evidence on the ticket; Director stops and asks user for clearer repro steps. **Do not proceed to fix code.**
  - `partially_reproduced` → document the actual symptom; Director decides whether to proceed as documented or escalate.
  - `blocked` → resolve the blocker (env, account, fixture) and retry.

### 6. Root cause + candidate fixes
- Invoke `cceo-software-engineer` with the reproduction report.
- The engineer:
  - Traces to root cause with corroborating evidence.
  - Generates candidate fixes (Generate-and-Filter).
  - Picks minimum-risk.

### 7. Adversarial verification (optional)
- For production-incident bugs, security-adjacent bugs, or fixes touching > the immediate symptom:
  - Spawn a second `cceo-software-engineer` instance prompted to refute the root cause.
  - If it can refute, return to step 6 with the new evidence.

### 8. Implementation
- Same `cceo-software-engineer` implements the chosen fix.
- Always includes a regression test.
- Runs the test suite; quotes results verbatim.

### 9. Validation
- Invoke `cceo-qa-env-manager` with `purpose=validate` (often a different environment than reproduction).
- Invoke `cceo-qa-validator` with the validation plan derived from the reproduction:
  - Primary journey: the original repro should now succeed.
  - Edge cases: surrounding cases that could have been affected.
  - Regression spot-checks: adjacent flows.
- Invoke `cceo-qa-comms` if the journey touches communications.

### 10. Reviewer panel (Tournament)
- All four reviewers run in parallel: `cceo-code-reviewer`, `cceo-security-engineer`, `cceo-performance-engineer`, `cceo-software-architect`.
- Director collects all verdicts and findings.

### 11. Loop-Until-Done
- If any reviewer or the validator returns blocking findings:
  - Re-invoke `cceo-software-engineer` with the specific findings.
  - Re-run validator (full or targeted at the changed area).
  - Re-run reviewer panel.
- Stop conditions:
  - All reviewers approve **and** validator returns `pass` → proceed to PR.
  - 3 iterations without convergence → escalate to user.

### 12. PR + ticket close-out
- Invoke `cceo-engineering-manager`.
- It composes the PR title and body, pushes the branch, opens the PR (draft or ready per user instruction), and comments on the ticket with the PR link and evidence summary.
- It does **not** auto-merge or auto-transition status without strong project signals.

### 13. Director declares completion
- Final summary: PR URL, ticket URL, what was changed, what was validated, what reviewers approved, follow-ups identified, overall confidence.

---

## Decision rules

- **Skip reproduction** only if the ticket includes a verifiable test failure with a clear path to the failing assertion. Even then, validate the failure manually before fixing.
- **Skip reviewers** only for trivial fixes (typo in user-facing string, comment). Document the skip.
- **Always include the security reviewer** for fixes touching auth, sessions, payments, persistence, file upload, external API, environment.
- **Always include a regression test** unless the codebase lacks any test infrastructure (then document the manual verification step).
- **Communications (email / OTP / magic-link / invite / push) are opt-in.** Invoke `cceo-qa-comms` and the configured email sink (maildrop / Mailtrap / etc.) **only when the bug's reproduction journey actually sends or depends on a message**. Bugs in unrelated surfaces (UI rendering, server errors, validation, etc.) do not trigger any comms call. If you find yourself about to poll an inbox for a bug that has nothing to do with email — stop.

## Common failure modes

- **Bug doesn't reproduce.** Don't fix code based on assumption. Push back to the user for clearer steps.
- **Root cause is in a dependency.** Stop. Open an upstream issue. Implement a workaround only if business-critical.
- **Fix passes tests but reviewer panel finds a security issue.** Iterate. Don't merge the fix and "follow up" on security separately.
- **Loop hits 3 iterations.** Escalate. Don't keep going.
