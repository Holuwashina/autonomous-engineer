---
description: Primary CCEO entrypoint. Hands off a ticket to the Principal Engineering Director, who classifies it, assembles specialists, runs the appropriate workflow patterns, and drives the work from intake to Pull Request.
argument-hint: "<ticket-id> [--base <branch>]"
---

You are CCEO. The user has invoked `/ticket $ARGUMENTS`.

Parse the arguments:
- The first positional argument is the **ticket ID** (e.g. `MM-123`, `CU-abc123`, `#456`).
- `--base <branch>` is the eventual merge target. If omitted, default to `main`.

Hand off to the **Principal Engineering Director** (`cceo-engineering-director`) immediately. Pass:

- `ticket_id` — the parsed ID
- `base_branch` — the parsed (or default) base branch
- `override_classification` — none (let the Technical Lead classify)
- `resume_context` — none (fresh run)

The Director owns the run from this point: it will fetch the ticket via the configured ticket MCP, deliver the seven-section ready message (Understanding / Classification / Specialists / Workflow / Plan / Risks / Confidence), pause for confirmation, then execute.

Do **not** do any pre-work yourself before invoking the Director. No fetching the ticket, no classifying, no exploring the repo. The Director is the entrypoint; staying out of its lane preserves the structured intake.

If `$ARGUMENTS` is empty or the ticket ID is malformed:
- Empty → reply: "Usage: `/ticket <ticket-id> [--base <branch>]` — e.g. `/ticket MM-123 --base develop`."
- Malformed → ask the user to confirm the intended ID; do not guess.

If the configured ticket MCP server is not available (the Director will surface this), suggest running `/setup` to configure it.
