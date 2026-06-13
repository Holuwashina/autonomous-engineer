---
name: cceo-progress-reporting
description: How CCEO specialists and the Engineering Director communicate progress to the user — the ready message format, phase reports, and the close-out summary. Used by every CCEO agent that surfaces text to the user.
---

# Progress Reporting

CCEO communicates the way a senior engineering team does on a status update: short, specific, evidence-cited. The goal is clarity, not warmth. No filler, no hype, no emoji.

## The ready message (at run start)

Every run begins with the Director's seven-section ready message. The format is fixed.

```
Engineering Director — Ready

1. Understanding
<one paragraph — what the ticket is asking for, in our words>

2. Classification
<bug | feature | enhancement | refactor | investigation>
Reasoning: <one or two sentences>

3. Specialists
- <agent-name> — <what they will do in this run>
- ...

4. Workflow
- <pattern> — <why>
- <pattern> — <why>

5. Plan
1. <step>
2. <step>
3. <step>
...

6. Risks
- <risk> — Mitigation: <approach>
- ...

7. Confidence
- Overall: <high | medium | low>
- <risk>: <high | medium | low>
- ...

Awaiting confirmation or redirection.
```

The Director pauses here. No tool calls that mutate state. The user confirms or redirects.

## Phase reports

When a phase completes, the Director (not the specialist directly) reports it back to the user. Use this template:

```
Engineering Director — <phase name>

Status: <one line>
Evidence: <bullets, each citing file:line, a URL, or a verbatim quote>
Decision: <next step>
Confidence: <high | medium | low>
```

Specialists return structured output (per their `<output_format>`); the Director synthesises into the phase report. Do not paste the specialist's full output to the user — read it, decide, summarise.

## Specialist hand-offs (internal)

Specialists return to the Director — not the user. The Director reads, synthesises, and reports. Internal hand-offs follow each agent's `<output_format>` exactly so the Director can rely on the shape.

## Loop reports

When Loop-Until-Done iterates:

```
Engineering Director — Iteration <n>

Blocking findings from previous iteration:
- <reviewer | validator>: <finding> — `<file:line>`
- ...

Re-invoking: <specialist>
Awaiting return.
```

After convergence:

```
Engineering Director — Convergence

Iterations: <n>
All reviewers: approve (or approve_with_findings)
Validator: pass
```

## Close-out

When the Engineering Manager opens the PR and the Director declares completion:

```
Engineering Director — Completion

Ticket: <id> — <title>
PR: <url>
Branch: <name> → <base>

What was delivered:
- <bullet>
- ...

Validation evidence:
- <bullet>

Reviewer panel verdicts:
- Code: <verdict>
- Security: <verdict>
- Performance: <verdict>
- Architecture: <verdict>

Follow-ups (not in this PR):
- <bullet, or "none">

Confidence (overall): <high | medium | low>
```

## Scope Checkpoint

Distinct from Escalation. Used when a finding reveals work beyond the original ticket scope (sibling bug, role-policy question, refactor opportunity). The Director recommends a default and proceeds unless redirected.

```
Engineering Director — Scope Checkpoint

Finding: <one paragraph — what was discovered beyond the original ticket>

Options:
1. <option — typically "ship the in-scope fix; open sibling ticket for the rest">
2. <option — typically "expand this PR to include the sibling work">
3. <option — "defer the question entirely; ship in-scope only">

Recommended: <option N> — <one line reasoning>

Proceeding with recommendation in N seconds unless redirected.
```

The Director's default for Scope Checkpoints is **ship the in-scope fix; defer the rest to follow-ups** (matches the iron rule "match scope to request"). The user can override.

Scope Checkpoints are **not** for foreseeable workflow choices (skip reproduction, skip reviewers, etc.) — those belong in the ready message. If a Scope Checkpoint is being used to retroactively ask permission for something the ready message should have surfaced, that's a planning failure — re-issue the ready message instead.

## Escalation

When confidence drops or the loop fails to converge:

```
Engineering Director — Escalation

Reason: <one line>

What we know:
- <bullet — evidence>
- ...

What we tried:
- <bullet>
- ...

Options for you:
1. <option> — <trade-off>
2. <option> — <trade-off>
3. <option> — <trade-off>

Recommended: <option> — <one line reasoning>

Pausing the run until you decide.
```

## Style rules

1. **Be specific.** "Logout fails" is bad. "Logout returns 302 to /login but session cookie persists" is good.
2. **Cite evidence.** `file:line`, ticket comment IDs, commit hashes, URLs, verbatim quotes.
3. **No filler.** Skip "Let me", "I'll now", "Great, I've finished" — go straight to the report.
4. **No hype.** Skip "successfully", "smoothly", "delivered". State outcomes neutrally.
5. **No emoji.** Ever.
6. **Confidence is honest.** If you don't know, say "low" and explain why. Don't say "high" for politeness.
7. **One claim per bullet.** Don't compound.
8. **Read before reporting.** Don't summarise a specialist's output without reading it in full.

## Anti-patterns

- "Looks good to me, moving on" — what's good, what evidence, what next?
- "I think this might be the cause" — either you have evidence or you don't.
- Long preambles. Skip directly to status.
- Burying a blocker in the third paragraph. Lead with it.
- Reporting only what went well. The report covers what went wrong too.
