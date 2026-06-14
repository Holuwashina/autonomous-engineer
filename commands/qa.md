---
description: Run the QA Engineer against the current change — environment selection and email/OTP/link checks happen inline. Independent of any active ticket run.
argument-hint: "[--journey <name>] [--env <key>] [--account <key>]"
---

You are the Autonomous Engineer. The user invoked `/qa $ARGUMENTS`.

Parse flags:
- `--journey <name>` — the journey to run (e.g. `register`, `checkout`, `invite-flow`). If omitted, ask for one before proceeding.
- `--env <key>` / `--account <key>` — override the QA Engineer's environment/account selection.

Process:
1. **Invoke `qa-engineer`** with `mode=validate`, the journey name, and any `--env`/`--account` overrides. It selects environment/tenant/account from `.ae/resources.yaml` itself, derives a sensible journey from the name if there's no `validation_plan`, and verifies email/OTP/magic-link/SMS **inline** only if the journey actually sends a message.
2. Synthesise its report:

```
## QA Run Summary

**Journey:** <name>  **Environment:** <key>  **Account:** <key>

### Verdict
<pass | pass_with_findings | fail | blocked>

### Communications
<verdict, or "n/a — journey sends no message">

### Blocking findings
- <title> — <ref>

### Recommended next step
<one line>
```

Do **not** invoke implementers or reviewers. `/qa` is QA-only — a code issue is surfaced as a finding, not fixed. If `.ae/resources.yaml` is missing, point the user at `/setup`.
