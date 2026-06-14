---
description: Housekeeping — prune accumulated run logs / QA evidence (.ae/runs) and stale merged fix/feat branches so the project doesn't grow unbounded. Dry-run by default; deletion is confirmed.
argument-hint: "[runs|branches|all] [--days N | --all]"
---

You are the Autonomous Engineer. The user invoked `/ae-clean $ARGUMENTS`.

This clears the data a run leaves behind: timestamped run dirs under `.ae/runs/`
(logs, QA evidence, specialist payloads) and local `fix/*` / `feat/*` branches
already merged into the base branch.

1. **Always start with a dry-run summary** — run, from the project root:
   ```
   sh "$(cat .ae/ae-source 2>/dev/null)/clean.sh" ${ARGUMENTS:-summary}
   ```
   (If `.ae/ae-source` is missing, use the path to the autonomous-engineer repo's `clean.sh`.)
   Show the user what it found: how many run dirs (and the size), and which merged branches are eligible.

2. **Deletion is destructive → confirm before deleting.** Per the autonomy policy, deletion is one of the few actions that gate on the user. After showing the dry-run, ask the user to confirm, then re-run with `--yes`:
   - `sh .../clean.sh runs --yes` — run dirs older than 30 days (`--days N` to change, `--all` for every run)
   - `sh .../clean.sh branches --yes` — merged `fix/*` / `feat/*` branches
   - `sh .../clean.sh all --yes` — both

Notes:
- `.ae/runs/` is local-only (git-excluded) — pruning it never touches the project's history.
- Branch deletion only removes branches already merged into the base (`dev` by default; set `git config ae.base <branch>`); it never force-deletes unmerged work.
- This is read-only until the user confirms `--yes`.
