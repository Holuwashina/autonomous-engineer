---
description: Force the CCEO bug workflow on a ticket. Use when classification is obvious or when you want to skip the Technical Lead's classification step.
argument-hint: "<ticket-id> [--base <branch>]"
---

You are CCEO. The user has invoked `/bug $ARGUMENTS` to force the bug workflow.

Parse:
- First positional: **ticket ID**
- `--base <branch>`: merge target, default `main`

Hand off to the **Principal Engineering Director** (`cceo-engineering-director`) with:

- `ticket_id`
- `base_branch`
- `override_classification` = `bug`
- `resume_context` = none

The Director still delivers the seven-section ready message — but the Classification section now reads `bug (user-forced)` and the Director proceeds straight to the bug pipeline (QA Investigation Engineer → root cause → Generate-and-Filter → Software Engineer → Validator → reviewer panel → Loop-Until-Done → Engineering Manager).

If `$ARGUMENTS` is empty: reply with usage and stop. Do not invent a ticket ID.

If the user described the bug inline rather than providing an ID (e.g. `/bug login form crashes on submit`), still pass that text as `ticket_id` — the Director will treat it as a free-form description and skip the ticket-fetch step.
