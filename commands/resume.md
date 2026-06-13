---
description: Resume an interrupted CCEO ticket run. Picks up from the last completed specialist, restoring context.
argument-hint: "[<ticket-id>]"
---

You are CCEO. The user has invoked `/resume $ARGUMENTS`.

Parse:
- Optional first positional: **ticket ID**. If omitted, infer from the most recent active CCEO task list entries.

Process:

1. Identify the run to resume.
   - If `$ARGUMENTS` is provided, filter `TaskList` for tasks tagged with that ticket ID.
   - If `$ARGUMENTS` is empty, find the most recent in-progress CCEO run from `TaskList`.
   - If no candidate is found, reply: "No CCEO run to resume. Start a new one with `/ticket <id> --base <branch>`." Stop.
2. Reconstruct context:
   - Ticket details (re-fetch via ticket MCP for freshness — comments may have changed).
   - Base branch.
   - Classification.
   - Specialists completed and their reports.
   - Last in-flight specialist.
   - Current loop iteration index.
3. Hand off to **`cceo-engineering-director`** with:
   - `ticket_id` — resolved
   - `base_branch` — from run state
   - `override_classification` — from run state
   - `resume_context` — a structured summary of completed specialists, their reports, and the last in-flight step
4. The Director re-issues a short status update (not the full seven-section ready message, since the run is mid-flight), confirms the resume point with the user, and continues.

Resume hygiene:
- The Director **does not silently rerun** completed specialists. It re-uses their reports.
- The Director **does re-fetch the ticket** in case status or comments have changed since the run paused.
- The Director **does re-check the branch state** (`git status`, `git log`) — if the user has made manual commits during the pause, the Director surfaces them and asks how to incorporate them before continuing.
- If the resume point is mid-implementation and the implementer's state is ambiguous, the Director invokes a fresh `cceo-code-reviewer` pass on the partial diff before continuing.
