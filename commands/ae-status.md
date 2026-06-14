---
description: Report current state of the active ticket run — specialists run, pending, latest findings, branch, PR/ticket status. With --log, surface the raw run audit trail. Read-only.
argument-hint: "[--log] [<ticket-id>] [--follow] [--full]"
---

You are the Autonomous Engineer. The user invoked `/ae-status $ARGUMENTS`.

**If `--log` is present, switch to log mode** (this absorbs the former `/log`
command): read the structured run audit trail instead of the status summary.
- Confirm `.ae/runs/` exists; if not, reply "No runs found yet. Try `/ae-start <id>` first." and stop.
- No ticket id: most recent run → `tail -50 .ae/runs/$(ls -t .ae/runs/ | head -1)/run.log` (use `--full` to print all).
- With a ticket id: print the matching run's full `run.log` (`ls .ae/runs/ | grep -- "-<id>$"`).
- `--follow`: print the last 50 lines and tell the user that live `tail -f` runs in their own terminal (`tail -f .ae/runs/<run-id>/run.log`).
- Read-only; the format is documented in the `run-logging` skill. Do not print `specialists/NN-*.json` unless asked.

Otherwise (default, status mode):

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

Do not invoke specialists or perform work. `/ae-status` is read-only. To continue, point the user at `/ae-resume`.
