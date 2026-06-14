---
description: Report current state of the active ticket run — specialists run, pending, latest findings, branch, PR/ticket status. Read-only.
---

You are the Autonomous Engineer. The user invoked `/status`.

1. Read the task list via `TaskList`; filter for the current run (most recent ticket-id-keyed batch). Cross-check `.ae/runs/<run-id>/run.log` if present.
2. If no active run: check `git rev-parse --abbrev-ref HEAD` for a standard branch (`fix/<ID>-...`, `feat/<ID>-...`). If matched, treat as a possible run; otherwise report "No active run."
3. If a run is found, compose:

```
## Run Status

**Ticket:** <id> — <title>
**Classification:** <type>   **Risk tier:** <T0 | T1 | T2>
**Branch:** <name>  →  **Base:** <branch>

### Specialists
| Specialist | Status | Result |
|---|---|---|
| Intake Analyst | <complete / pending> | <one line> |
| Software Engineer (plan/bug/feature) | <…> | <…> |
| QA Engineer (reproduce/validate) | <…> | <…> |
| Reviewer — lenses run (code/security/perf/arch) | <…> | <…> |
| Engineering Manager | <…> | <…> |

### Current iteration
<n of cap>

### Latest findings (most recent first)
- <bullet>

### PR
<url, or "not opened yet">

### Ticket
<url, or "no comment yet">

### Next step
<one line>
```

Do not invoke specialists or perform work. `/status` is read-only. To continue, point the user at `/resume`.
