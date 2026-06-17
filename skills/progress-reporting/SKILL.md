---
name: progress-reporting
description: How the Orchestrator and specialists communicate progress to the user — the ready message format, phase reports, and the close-out summary. Used by every Autonomous Engineer agent that surfaces text to the user.
---

# Progress Reporting

Autonomous Engineer communicates the way a senior engineering team does on a status update: short, specific, evidence-cited. The goal is clarity, not warmth. No filler, no hype, no emoji.

## The ready message (at run start)

Every run begins with the Orchestrator's ready message. The format is fixed.

```
Orchestrator — Ready

1. Understanding
<one paragraph — what the ticket is asking for, in our words>

2. Classification
<bug | feature | enhancement | refactor | investigation>
Reasoning: <one or two sentences>

3. Risk tier
<T0 | T1 | T2> — <the trigger that set it>

4. Specialists
- <agent-name> — <what they will do in this run>
- ...

5. Workflow
- <pattern> — <why>

6. Plan
1. <step>
2. <step>
...
Estimated agent calls: <n>

7. Risks
- <risk> — Mitigation: <approach>

8. Confidence
- Overall: <high | medium | low>
- <risk>: <high | medium | low>

Awaiting confirmation or redirection.
```

The Orchestrator pauses here. No tool calls that mutate state. The user confirms or redirects.

## Phase reports — show the work, not just the verdict

When a phase completes, the Orchestrator reports it back **with the concrete evidence the specialist produced** — so the user can see the claim is real, not hallucinated. Every verdict must be backed by a verbatim artifact. Template:

```
Orchestrator — <phase name>

Status: <one line verdict>
Evidence:
  <2–6 lines of the ACTUAL artifact — verbatim, quoted/fenced — not a paraphrase>
Detail: .ae/runs/<run-id>/specialists/NN-<name>.json
Decision: <next step>
Confidence: <high | medium | low>
```

What "Evidence" must contain, per specialist (quote the real thing, trimmed to the key lines):

- **QA reproduce** — the failing proof: the exact command + its verbatim failing output (e.g. `Expected: 17.99 / Received: 17.991`), or the API call `METHOD URL → STATUS` + body, or screenshot path. Plus the control path ("works for a manager"). If there's no concrete failure shown, it's **not** reproduced.
- **Software engineer** — the changed files with `file:line`, the chosen fix (1–3 lines of the actual diff), the **Codebase findings** note (what was reused), and the **verbatim** test + type-check output (`Tests: N passed`, `tsc` clean). No "tests pass" without the quoted line.
- **QA validate** — pass/fail **per acceptance criterion** each with its evidence ref; the verbatim suite output; for UI, the per-breakpoint result + screenshot paths.
- **Reviewer (each lens)** — verdict + each finding citing `file:line`. "approve" with zero specifics on a non-trivial diff is suspect — note that.

Quote the real artifact (trimmed), then point at the JSON for the full record. **A verdict with no verbatim evidence is treated as unverified — re-run or escalate, don't pass it on.** This is the anti-hallucination guard: the user (and you) trust the proof, not the agent's say-so.

## Specialist hand-offs (internal)

Specialists return to the Orchestrator — not the user. The Orchestrator reads, synthesises, and reports. Internal hand-offs follow each agent's `<output_format>` exactly so the Orchestrator can rely on the shape.

## Loop reports

```
Orchestrator — Iteration <n>

Blocking findings from previous iteration:
- <reviewer:lens | validator>: <finding> — `<file:line>`

Re-invoking: <specialist>
Awaiting return.
```

After convergence:

```
Orchestrator — Convergence

Iterations: <n of cap>
Reviewer lenses: approve (or approve_with_findings)
Validator: pass
```

## Close-out

When the Engineering Manager opens the PR and the Orchestrator declares completion:

```
Orchestrator — Completion

Ticket: <id> — <title>
Risk tier: <T0 | T1 | T2>
PR: <url>
Branch: <name> → <base>

What was delivered:
- <bullet>

Validation evidence:
- <bullet>

Reviewer verdicts (lenses that ran):
- <lens>: <verdict>

Follow-ups (not in this PR):
- <bullet, or "none">

Confidence (overall): <high | medium | low>
```

## Scope Checkpoint

Distinct from Escalation. Used when a finding reveals work beyond the original ticket scope (sibling bug, role-policy question, refactor opportunity). The Orchestrator recommends a default and proceeds unless redirected.

```
Orchestrator — Scope Checkpoint

Finding: <one paragraph — what was discovered beyond the original ticket>

Options:
1. <option — typically "ship the in-scope fix; open sibling ticket for the rest">
2. <option — typically "expand this PR to include the sibling work">
3. <option — "defer the question entirely; ship in-scope only">

Recommended: <option N> — <one line reasoning>

Proceeding with recommendation in N seconds unless redirected.
```

The default for Scope Checkpoints is **ship the in-scope fix; defer the rest to follow-ups** (matches the iron rule "match scope to request"). The user can override.

Scope Checkpoints are **not** for foreseeable workflow choices (skip reproduction, skip reviewers, etc.) — those belong in the ready message. If a Scope Checkpoint is being used to retroactively ask permission for something the ready message should have surfaced, that's a planning failure — re-issue the ready message instead.

## Escalation

When confidence drops or the loop fails to converge:

```
Orchestrator — Escalation

Reason: <one line>

What we know:
- <bullet — evidence>

What we tried:
- <bullet>

Options for you:
1. <option> — <trade-off>
2. <option> — <trade-off>

Recommended: <option> — <one line reasoning>

Pausing the run until you decide.
```

## Style rules

1. **Be specific.** "Logout fails" is bad. "Logout returns 302 to /login but session cookie persists" is good.
2. **Cite evidence.** `file:line`, ticket comment IDs, commit hashes, URLs, verbatim quotes.
3. **No filler.** Skip "Let me", "I'll now", "Great, I've finished" — go straight to the report.
4. **No hype.** Skip "successfully", "smoothly", "delivered". State outcomes neutrally.
5. **No emoji.** Ever.
6. **Confidence is honest.** If you don't know, say "low" and explain why.
7. **One claim per bullet.** Don't compound.
8. **Read before reporting.** Don't summarise a specialist's output without reading it in full.

## Anti-patterns

- "Looks good to me, moving on" — what's good, what evidence, what next?
- "I think this might be the cause" — either you have evidence or you don't.
- Long preambles. Skip directly to status.
- Burying a blocker in the third paragraph. Lead with it.
- Reporting only what went well. The report covers what went wrong too.
