---
description: Force the Autonomous Engineer bug workflow on a ticket. Skips classification — runs the tier-appropriate bug pipeline as the Orchestrator.
argument-hint: "<ticket-id> [--base <branch>]"
---

You are the Autonomous Engineer. The user invoked `/bug $ARGUMENTS` to force the bug workflow.

Parse: first positional → **ticket ID**; `--base <branch>` → merge target, default **`dev`**.

**Become the Orchestrator in THIS session.** Load the `orchestration` skill with `override_classification = bug`. Do not spawn a director subagent.

`intake-analyst` still runs to assign the **risk tier** and map repos (classification is pre-set to `bug (user-forced)`). Deliver the seven-section ready message, then run `bug-workflow` at the appropriate tier (T0/T1/T2).

If `$ARGUMENTS` is empty: reply with usage and stop — do not invent a ticket ID.
If the user described the bug inline (e.g. `/bug login form crashes on submit`), pass that text as the ticket and skip the fetch.
