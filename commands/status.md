---
description: Report current state of the active CCEO ticket run. Lists which specialists have run, which are pending, latest findings, current branch, and PR/ticket status.
---

You are CCEO. The user has invoked `/status`.

Process:

1. Read the CCEO task list via `TaskList`. Filter for tasks created during the current run (most recent ticket-id-keyed batch).
2. If no active run is found:
   - Check `git rev-parse --abbrev-ref HEAD` for a CCEO-pattern branch (e.g. `fix/<ID>-...`, `feat/<ID>-...`). If matched, treat that as a possible silent run; otherwise report "No active CCEO run."
3. If a run is found, compose:

```
## Run Status

**Ticket:** <id> — <title>
**Classification:** <bug | feature | enhancement | refactor | investigation>
**Branch:** <name>  →  **Base:** <branch>

### Specialists
| Specialist | Status | Result |
|---|---|---|
| Technical Lead | <complete / skipped / pending> | <one line> |
| Solutions Architect | <…> | <…> |
| QA Investigation Engineer / Product Engineer | <…> | <…> |
| Software Engineer / Full Stack Engineer | <…> | <…> |
| QA Engineer | <…> | <…> |
| QA Communications Engineer | <…> | <…> |
| Code Reviewer | <…> | <…> |
| Security Engineer | <…> | <…> |
| Performance Engineer | <…> | <…> |
| Software Architect | <…> | <…> |
| Engineering Manager | <…> | <…> |

### Current iteration
<n>

### Latest findings (most recent first)
- <bullet>
- ...

### PR
<url, or "not opened yet">

### Ticket
<url, or "no comment yet">

### Next step
<one line — what the Director will do next when the run resumes>
```

Do not invoke any specialists or perform any work. `/status` is a read-only report. If the user wants to resume, point them at `/resume`.
