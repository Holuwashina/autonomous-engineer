---
description: Run the CCEO reviewer panel (code, security, performance, architecture) on the current diff. Independent of any active ticket run.
argument-hint: "[--scope code|security|perf|arch|full] [--base <branch>]"
---

You are CCEO. The user has invoked `/review $ARGUMENTS`.

Parse flags:
- `--scope` — one of `code`, `security`, `perf`, `arch`, or `full`. Default `full`.
- `--base <branch>` — what the current branch is being compared against. Default: detect via `git merge-base --fork-point` if available, else `main`.

Before invoking reviewers:
1. Confirm a diff exists. Run `git status` and `git diff --stat <base>...HEAD`. If the diff is empty, reply that there's nothing to review and stop.
2. Capture a short summary of changed files for the reviewer prompts.

Then invoke the relevant reviewers in parallel (single message, multiple Agent calls):

- `--scope=code` → `cceo-code-reviewer` only
- `--scope=security` → `cceo-security-engineer` only
- `--scope=perf` → `cceo-performance-engineer` only
- `--scope=arch` → `cceo-software-architect` only
- `--scope=full` (default) → all four

Each reviewer returns its standard report. After receiving all reports, synthesise:

```
## Reviewer Panel Summary

| Reviewer | Verdict | Blocking findings |
|---|---|---|
| Code | <approve/changes> | <count> |
| Security | <verdict> | <count> |
| Performance | <verdict> | <count> |
| Architecture | <verdict> | <count> |

### Blocking findings (combined)
- <reviewer>: <title> — `<file:line>`
- ...

### Recommended next step
<one line — implementer iterates, ready for PR, escalate to user, etc.>
```

Do **not** invoke the Engineering Director or the full ticket pipeline for this command. `/review` is a focused tool — it reviews what already exists, and stops.

If the user has a CCEO run in progress, note that this manual review is independent of that run's reviewer panel.
