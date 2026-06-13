---
name: cceo-feature-workflow
description: The canonical CCEO feature pipeline — from intake through planning, implementation, validation, review, and PR. Used for any ticket classified as feature or enhancement.
---

# Feature workflow

The end-to-end pipeline for any ticket classified as `feature` or `enhancement`.

## Phases

### 1. Intake
- Director fetches the ticket via the ticket MCP (`cceo-ticket-protocol`).
- Director delivers the seven-section ready message.
- User confirms or redirects.

### 2. Classification
- If `/feature` forced it, skip. Otherwise invoke `cceo-technical-lead`.
- Output: `feature` (or `enhancement`) + reasoning + reviewer-scope recommendation.

### 3. Repository mapping
- Invoke `cceo-solutions-architect`.
- Output: which repos are affected, cross-repo couplings, blast radius signals.

### 4. Feature planning
- Invoke `cceo-product-engineer`.
- Output: acceptance criteria, users/journeys, data model changes, API surface, UI surface, dependencies, ordered implementation steps, validation plan.

If the Product Engineer flags that acceptance criteria were derived (not explicit in the ticket), the Director pauses and asks the user to confirm before implementation begins.

### 5. Implementation
- Invoke `cceo-fullstack-engineer` with the plan.
- The engineer executes step-by-step:
  - Branch off `base_branch`.
  - For each step: read affected files → modify → write tests → run tests → commit.
  - Reuse existing primitives (don't invent parallels).
  - Run full test suite at the end.
  - Self-review the diff.

### 6. Environment selection for validation
- Invoke `cceo-qa-env-manager` with `purpose=validate`.
- Output: environment / tenant(s) / account(s) for the validation pass.

### 7. Validation
- Invoke `cceo-qa-validator` with the plan's validation strategy:
  - Primary journey per acceptance criterion.
  - Edge cases per the plan.
  - Cross-role / cross-tenant checks (use `cceo-multi-tenant` for multi-tenant apps).
- Invoke `cceo-qa-comms` if the feature touches email / OTP / magic-link / invitation / push.

### 8. Reviewer panel (Tournament)
- All four reviewers in parallel: `cceo-code-reviewer`, `cceo-security-engineer`, `cceo-performance-engineer`, `cceo-software-architect`.
- For auth / payments / persistence / trust-boundary features, the full panel is mandatory.

### 9. Loop-Until-Done
- If any reviewer or the validator returns blocking findings:
  - Re-invoke `cceo-fullstack-engineer` with the specific findings.
  - Re-run validator (full or targeted).
  - Re-run reviewer panel.
- Stop conditions:
  - All reviewers approve **and** validator returns `pass` → proceed to PR.
  - 3 iterations without convergence → escalate to user.

### 10. PR + ticket close-out
- Invoke `cceo-engineering-manager`.
- It composes title/body (acceptance criteria checklist in the body), pushes the branch, opens the PR, comments on the ticket.

### 11. Director declares completion
- Final summary: PR URL, ticket URL, what was built, acceptance criteria coverage, validation evidence, reviewer verdicts, follow-ups, overall confidence.

---

## Decision rules

- **Acceptance criteria must be explicit.** If derived from the description, confirm with the user before implementing.
- **Always plan migrations as discrete steps** ahead of code that depends on them.
- **Always reuse existing primitives.** The Product Engineer names them; the Full Stack Engineer uses them.
- **Always validate cross-role / cross-tenant** in multi-tenant codebases when the feature touches authorization or visible UI.
- **Always run the full reviewer panel** for auth, payments, persistence, trust boundaries, public API additions.
- **Communications (email / OTP / magic-link / invite / push) are opt-in.** Invoke `cceo-qa-comms` and the configured email sink (maildrop / Mailtrap / etc.) **only when the feature's acceptance criteria reference a message** (e.g. "user receives a verification email"). Features in unrelated surfaces (reports, dashboards, settings UI, internal APIs) do not trigger any comms call.

## Common failure modes

- **Plan ambiguity reaches implementation.** If the implementer needs to "decide" something the plan didn't decide, that's a planning failure. Report it to the Director — don't decide unilaterally.
- **Feature flag forgotten.** If the plan called for a flag and the implementer skipped it, the validator catches it (the feature shouldn't be live without the flag in a canary).
- **Acceptance criterion declared "covered" without a test.** Block. Either add the test or document the manual verification step.
- **Loop hits 3 iterations.** Escalate.
