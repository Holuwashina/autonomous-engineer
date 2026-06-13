---
name: run-logging
description: How Autonomous Engineer writes a structured, grep-friendly audit log for every ticket run — file layout, line format, what every specialist must emit, how to tail it, and how /log surfaces it. Used by the Engineering Director and every specialist that returns to the Director.
---

# Autonomous Engineer Run Logging

Every run writes a structured audit trail to `.ae/runs/<run-id>/`. Engineers can grep it after the fact, attach it to incident reports, diff it across runs. Without this log, the only record of what was done is the chat scrollback — which is hard to share, hard to search, and disappears.

## File layout

```
.ae/
└── runs/
    └── 2026-06-13T03-15-42Z-MM-123/      ← run directory
        ├── run.log                         ← timestamped event stream (canonical)
        ├── ticket.md                       ← fetched ticket content (for re-runs)
        ├── ready-message.md                ← the seven-section ready message
        ├── specialists/
        │   ├── 01-technical-lead.json      ← each specialist spawn's payload + return
        │   ├── 02-solutions-architect.json
        │   ├── 03-qa-env-manager.json
        │   └── ...
        ├── decisions.md                    ← scope checkpoints, user inputs, rationale
        └── final-summary.md                ← close-out (or escalation)
```

The run-id is `<UTC-timestamp>-<ticket-id-slug>`. Use `T03-15-42Z` (dashes for the time), not `T03:15:42Z` — colons break shell completion and some filesystems.

## .gitignore

Add `.ae/runs/` to your project's `.gitignore`. Run logs contain ticket descriptions and code references — fine to keep local, awkward to commit.

```sh
echo '.ae/runs/' >> .gitignore
```

## Log line format

```
[<ISO-8601-UTC>] [<LEVEL>] [<PHASE>] [<ACTOR>] <message>
```

One event per line. Fields:

| Field | Values | Example |
|---|---|---|
| Timestamp | ISO-8601 UTC, second precision | `2026-06-13T03:15:42Z` |
| Level | `INFO` / `WARN` / `ERROR` / `DECIDE` / `PARALLEL` | `INFO` |
| Phase | `intake` / `classify` / `arch` / `env` / `repro` / `rootcause` / `impl` / `validate` / `review` / `loop` / `pr` / `close` / `escalate` | `intake` |
| Actor | Agent name without the `autonomous-engineer-` prefix | `director`, `technical-lead`, `qa-reproducer` |
| Message | Free-form, single line, ≤200 chars | `Fetched ticket 86exwk8yx (10 fields)` |

Multi-line content (specialist returns, tracebacks) does not go in `run.log` — it goes in the corresponding `specialists/NN-<name>.json` file, and the log references that file:

```
[2026-06-13T03:15:42Z] [INFO] [classify] [technical-lead] Returned bug (verdict + reasoning → specialists/01-technical-lead.json)
```

## What every actor logs

### Director (anchor of the log)

The Director opens and closes the run, and emits a line at every phase boundary.

```
[T] [INFO]  [intake]    [director] Run started: ticket=86exwk8yx base=develop classification=auto
[T] [INFO]  [intake]    [director] Fetched ticket (title: "Broken subscription email CTA")
[T] [INFO]  [intake]    [director] Ready message delivered, awaiting user confirmation
[T] [INFO]  [intake]    [director] User confirmed; entering execution
[T] [PARALLEL] [classify] [director] Fanout: technical-lead || solutions-architect
[T] [INFO]  [classify]  [director] technical-lead complete → bug (specialists/01-…)
[T] [INFO]  [arch]      [director] solutions-architect complete → 1 repo, 0 coupling (specialists/02-…)
[T] [INFO]  [env]       [director] Spawning qa-env-manager
...
[T] [DECIDE] [review]   [director] Scope Checkpoint: sibling broken links at lines 495/872 → recommend defer
[T] [INFO]  [review]    [director] User accepted defer; opening follow-up ticket reference
[T] [PARALLEL] [review] [director] Fanout: code-reviewer || security || performance || architect
...
[T] [INFO]  [pr]        [director] PR opened: <url>
[T] [INFO]  [close]     [director] Run complete: PR <url>, ticket updated, 0 escalations
```

### Specialists

Each specialist emits exactly two lines: spawn and return. Anything richer goes in the JSON file.

```
[T] [INFO] [<phase>] [<name>] Spawned with: <one-line context>
[T] [INFO] [<phase>] [<name>] Returned: <one-line verdict>
```

If a specialist errors:
```
[T] [ERROR] [<phase>] [<name>] <one-line error> (full trace → specialists/NN-<name>.json)
```

### Escalations

```
[T] [ERROR] [escalate] [director] Loop did not converge after 3 iterations (findings → decisions.md)
```

## How to write the log (Director's bash helper)

The Director sets the run directory once at intake and emits lines via a small shell function. Run the setup once per run, then call `log` for every event.

```bash
RUN_ID="$(date -u +%Y-%m-%dT%H-%M-%SZ)-${TICKET_ID}"
RUN_DIR=".ae/runs/$RUN_ID"
mkdir -p "$RUN_DIR/specialists"

log() {
  # log <LEVEL> <PHASE> <ACTOR> <message>
  printf '[%s] [%s] [%s] [%s] %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "$4" \
    | tee -a "$RUN_DIR/run.log"
}

log INFO intake director "Run started: ticket=$TICKET_ID base=$BASE_BRANCH"
```

The `tee` means the user sees the line in the chat too — surfaces progress without extra reporting overhead.

## How specialists write their JSON

```bash
cat > "$RUN_DIR/specialists/01-technical-lead.json" <<'JSON'
{
  "actor": "technical-lead",
  "spawned_at": "2026-06-13T03:15:42Z",
  "returned_at": "2026-06-13T03:16:34Z",
  "input": { "ticket_id": "86exwk8yx" },
  "output": {
    "verdict": "bug",
    "confidence": "high",
    "reasoning": "...",
    "signals": ["..."]
  }
}
JSON
```

Each specialist file is the source of truth for its run output. The `run.log` is the index.

## How `/log` reads it

The `/log` slash command:
- Without args: `tail -50 .ae/runs/$(ls -t .ae/runs/ | head -1)/run.log`
- With ticket id: find the matching run directory, print the full log
- `--follow`: tail -f the active run's log

See `commands/log.md`.

## Retention

Default: keep all runs locally. They're cheap (each `run.log` is typically <50KB). Manual cleanup:

```sh
# Drop runs older than 30 days
find .ae/runs -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +
```

Autonomous Engineer does not auto-delete runs — old logs are evidence for retrospectives.

## Anti-patterns

- Writing multi-line content into `run.log` — breaks grep, breaks tail. Put it in the JSON file and reference it from the log.
- Using colons (`:`) or other shell-unsafe characters in the run-id. Dashes only.
- Skipping the `log` call for "small" steps. The whole point is a complete trace — partial logs are worse than no log because the gaps look like the work didn't happen.
- Logging credentials or secret field values. Log keys and references, never values.
- Letting specialist JSON files balloon — keep them to the structured output shape from the agent's `<output_format>`, not the full chain of thought.
