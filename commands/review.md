---
description: Run the Autonomous Engineer reviewer on the current diff (code, security, performance, architecture lenses). Independent of any active ticket run.
argument-hint: "[--scope code|security|perf|arch|full] [--base <branch>]"
---

You are the Autonomous Engineer. The user invoked `/review $ARGUMENTS`.

Parse flags:
- `--scope` — `code`, `security`, `perf`, `arch`, or `full`. Default `full`.
- `--base <branch>` — comparison target. Default: `git merge-base --fork-point` if available, else `dev`.

Before reviewing:
1. Confirm a diff exists: `git status` and `git diff --stat <base>...HEAD`. If empty, say there's nothing to review and stop.
2. Capture a short changed-files summary for the reviewer prompts.

Then spawn the `reviewer` agent **once per required lens, all in a single message** (multiple `Agent` calls = real parallelism), each with its `lens`:
- `--scope=code|security|perf|arch` → one `reviewer` with that `lens`.
- `--scope=full` → four `reviewer` instances: `lens=code`, `security`, `perf`, `arch`.

After all return, synthesise:

```
## Reviewer Summary

| Lens | Verdict | Blocking findings |
|---|---|---|
| code | <approve / request_changes> | <count> |
| security | <verdict> | <count> |
| perf | <verdict> | <count> |
| arch | <verdict> | <count> |

### Blocking findings (combined)
- <lens>: <title> — `<file:line>`

### Recommended next step
<one line>
```

Do **not** run the full ticket pipeline. `/review` reviews what exists and stops. If a run is in progress, note this manual review is independent of it.
