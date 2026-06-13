---
description: Run the QA Engineer (plus the Communications Engineer if the journey involves email/OTP/links) against the current change. Independent of any active ticket run.
argument-hint: "[--journey <name>] [--env <key>] [--account <key>]"
---

You are the Autonomous Engineer. The user has invoked `/qa $ARGUMENTS`.

Parse flags:
- `--journey <name>` — short name for the journey to run (e.g. `register`, `checkout`, `invite-flow`). If omitted, ask the user for one before proceeding.
- `--env <key>` — override the QA Environment Engineer's environment selection.
- `--account <key>` — override the account selection.

Process:

1. **Invoke `qa-environment-engineer`** with `purpose=validate` to confirm or select environment, tenant, and account. If flags override the manager's defaults, pass them through.
2. **Invoke `qa-engineer`** with the journey name and the environment selection. Pass an empty `validation_plan` if there isn't one from an active run — the Validator will derive a sensible journey from the name.
3. **If the journey touches email / OTP / magic-link / invite / push:** invoke `qa-communications-engineer` in parallel to capture the corresponding artefacts.
4. Synthesise the Validator's report (and Comms report, if present) into a single summary:

```
## QA Run Summary

**Journey:** <name>  **Environment:** <key>  **Account:** <key>

### Validator verdict
<pass | pass_with_findings | fail>

### Communications verdict
<verdict, or "n/a">

### Blocking findings
- <title> — <ref>
- ...

### Recommended next step
<one line — implementer iterates, ready for review, escalate to user, etc.>
```

Do **not** invoke implementers or reviewers. `/qa` is QA-only. If the journey reveals a code issue, surface it as a finding — don't fix it.

If `.ae/resources.yaml` is missing, point the user at `/setup`.
