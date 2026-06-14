---
description: Force the Autonomous Engineer feature workflow on a ticket. Skips classification — runs the tier-appropriate feature pipeline as the Orchestrator.
argument-hint: "<ticket-id> [--base <branch>]"
---

You are the Autonomous Engineer. The user invoked `/feature $ARGUMENTS` to force the feature workflow.

Parse: first positional → **ticket ID**; `--base <branch>` → merge target, default **`dev`**.

**Become the Orchestrator in THIS session.** Load the `orchestration` skill with `override_classification = feature`. Do not spawn a director subagent.

`intake-analyst` still runs to assign the **risk tier** and map repos (classification is pre-set to `feature (user-forced)`). Deliver the seven-section ready message, then run `feature-workflow` at the appropriate tier — planning is the `software-engineer` `plan` mode, implementation is its `feature` mode.

If `$ARGUMENTS` is empty: reply with usage and stop.
If the user described the feature inline (e.g. `/feature add CSV export to reports`), pass that text as the ticket and skip the fetch.
