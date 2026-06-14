---
name: workflow-patterns
description: The six adaptive workflow patterns the Orchestrator composes when driving a run. Use this to decide which patterns fit a ticket, and how to compose them.
---

# Autonomous Engineer Workflow Patterns

Six patterns. The Orchestrator **composes** them — most runs use two or three. Running all six is a smell.

## The patterns

### 1. Classify-and-Act
**Shape:** Understand → Route → Execute.

Use when the request is well-scoped, the implementation is obvious, and one specialist can finish it. Trivial bug fixes, single-file documentation updates, small enhancements.

**Example composition:** Technical Lead classifies → Software Engineer fixes → single Code Reviewer approves → Engineering Manager opens PR.

Skip when the work is exploratory, ambiguous, or risky.

---

### 2. Fanout-and-Synthesize
**Shape:** Decompose into parallel specialist tasks → run them concurrently → synthesise.

Use when independent work streams must complete before the next phase can start, **and** synthesis across results is genuinely useful (not when work can pipeline through).

**Example composition:** Intake Analyst maps repos → Orchestrator fans out `software-engineer` (`mode=plan`) per repo → synthesises into a single plan → fans out `software-engineer` (`mode=feature`) per repo.

Prefer **pipelining** when results don't need to be synthesised — that is, when each specialist's output can flow directly into the next without combining across siblings.

---

### 3. Adversarial Verification
**Shape:** A primary specialist produces a result → an independent skeptic tries to refute it.

Use when a finding could be plausible-but-wrong. Bug root-cause analyses, security findings, perf claims.

**Example composition:** Software Engineer claims root cause → spawn a second Software Engineer instance with the prompt "try to refute this root cause; default to refuted=true if uncertain". If the skeptic can't refute, the root cause survives.

Use sparingly — every adversarial pass is extra work. Use it when stakes warrant it.

---

### 4. Generate-and-Filter
**Shape:** Generate ≥2 candidate solutions → score against constraints → pick the safest.

Use when more than one safe solution exists, and the trade-offs matter. Bug fixes (multiple places to intercept) and feature design decisions are the typical cases.

**Example composition:** Software Engineer generates 2–3 fix options → table of (diff scope, side effects, risk, blast radius) → minimum-risk option selected → implementation proceeds.

Document the alternatives even when not chosen — they become follow-ups.

---

### 5. Tournament
**Shape:** Multiple independent specialists evaluate the same artefact → majority/consensus determines verdict.

Use when stakes warrant consensus, or when a single reviewer's judgement is insufficient — typically the four-reviewer panel itself is a tournament.

**Example composition:** four independent `reviewer` instances (`lens=code` / `security` / `perf` / `arch`) evaluate the diff in parallel → tournament verdict is the union of their findings. Any blocking finding from any lens requires resolution.

Don't substitute tournament for adversarial verification — tournaments evaluate, adversaries refute.

---

### 6. Loop-Until-Done
**Shape:** Implement → Validate → Review → if findings, iterate; otherwise complete.

Use when the validator or reviewers may surface findings that need another implementation pass. This is the **default close-out pattern** for any non-trivial run.

**Example composition:** Software Engineer fixes → Validator runs → reviewers run → blocking findings? → Software Engineer iterates with the findings → re-validate / re-review → exit when no blocking findings.

**Cap:** 3 iterations without convergence → escalate to user. Looping forever is a process failure.

---

## How the Orchestrator composes patterns

### Default pipelines (described in detail in `bug-workflow` and `feature-workflow`)

**Bug:** Classify-and-Act (intake) → Adversarial Verification (root cause) → Generate-and-Filter (fix options) → Loop-Until-Done (implement/validate/review) → Tournament (reviewer panel).

**Feature:** Classify-and-Act (intake) → Fanout-and-Synthesize (if multi-repo) → Loop-Until-Done (implement/validate/review) → Tournament (reviewer panel).

**Refactor / Investigation:** Classify-and-Act, often with much lighter validation.

### When to add patterns

- **Adversarial Verification** when: production-incident bug, security claim, perf claim, "fix" that touches more than expected.
- **Fanout-and-Synthesize** when: ≥2 repos affected with independent work streams that must complete before downstream synthesis.
- **Generate-and-Filter** when: ≥2 plausible safe solutions exist. Skip when only one viable fix exists.

### When to drop patterns

- **Drop the reviewer Tournament** *only* when blast radius is "none" (e.g. typo in a comment). Document the skip.
- **Drop Loop-Until-Done** when validation passes first try and reviewers all approve. Do not mark a Loop as "complete" without at least one iteration finishing cleanly.

---

## Anti-patterns

- Running all six patterns by default. Composition, not bundling.
- Using Tournament for things one reviewer would catch.
- Using Adversarial Verification for findings that aren't suspicious.
- Looping without a cap.
- Skipping reviewer Tournament for auth / payments / persistence / trust boundaries — these always run the full panel, regardless of risk perception.
