---
description: Tail or display a CCEO run log. Without args, shows the last 50 lines of the most recent run. With a ticket id, prints the full log for that run.
argument-hint: "[<ticket-id>] [--follow] [--full]"
---

You are CCEO. The user has invoked `/log $ARGUMENTS`.

Parse flags:
- First positional (optional): `<ticket-id>` — filters to the matching run.
- `--follow` — tail the active run's log (use `tail -f`).
- `--full` — print the full log (default is `tail -50`).

Process:

1. Confirm `.cceo/runs/` exists. If not, reply: "No CCEO runs found yet. Try `/ticket <id>` first." Stop.

2. **No ticket id, no `--follow`** — default mode:
   - Find the most recent run: `LATEST=$(ls -t .cceo/runs/ | head -1)`
   - Print: `tail -50 ".cceo/runs/$LATEST/run.log"` (or full if `--full`)
   - Header: `Run: $LATEST` then the lines.

3. **With ticket id** — filter:
   - `MATCH=$(ls .cceo/runs/ | grep -- "-${TICKET_ID}\$" | head -1)`
   - If empty: "No run found for ticket `<id>`. Recent runs:" + `ls -t .cceo/runs/ | head -5`.
   - Otherwise: print `.cceo/runs/$MATCH/run.log` (full).

4. **`--follow`** — tail the active run:
   - Find the most recent run (same as no-args mode).
   - `tail -f` is not appropriate inside Claude Code (no terminal). Instead: print the last 50 lines and tell the user: "Re-run /log to refresh. Or in your own terminal: `tail -f .cceo/runs/<run-id>/run.log`".

5. **Post-print** — surface useful next steps:
   - If the run is still active (last log line is not `[close]` or `[escalate]`): suggest `/status` for the structured view.
   - If complete: link to the run directory: `.cceo/runs/<run-id>/` and mention the `specialists/` JSON files for detailed per-step output.

This command is **read-only**. It does not modify any CCEO state. Safe to run anytime — including mid-run.

Notes:
- The run log format is documented in `cceo-run-logging`.
- If a run id can't be parsed but a positional was provided, treat the positional as a ticket id substring.
- Do not print the contents of `specialists/NN-*.json` files unless the user asks — they can be large. Mention they exist and the path to read them with `Read`.
