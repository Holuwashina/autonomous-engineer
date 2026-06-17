---
description: Update this project's Autonomous Engineer install to the latest release — pulls the newest source, re-syncs agents/commands/skills, prunes anything removed upstream, refreshes hooks, and re-stamps the version.
argument-hint: ""
---

You are the Autonomous Engineer. The user invoked `/ae-update`.

This brings the project up to the latest AE release. The AE files in `.claude/`
are copies of the source repo, so an update is: pull the newest source, then
re-sync this project (copy changed files, prune removed ones, refresh the safety
hooks + git-excludes, re-stamp the version).

1. **Run the updater** from the project root:
   ```
   sh "$(cat .ae/ae-source 2>/dev/null)/update.sh" .
   ```
   (If `.ae/ae-source` is missing, the install never completed — run
   `sh <autonomous-engineer>/setup.sh` once first.)

2. **Report the version delta** it prints (e.g. `2.0.0 → 2.1.0`) and any files it
   pruned. Updating is non-destructive to the project's own code: it only touches
   AE-managed files (tracked in `.ae/manifest`), which are git-excluded anyway.

3. **Tell the user to restart Claude Code** — newly changed agents/commands/skills
   only load on restart.

Notes:
- To update **every** project at once, the user can loop in the terminal:
  `for p in ~/code/*; do [ -f "$p/.ae/ae-source" ] && sh "$(cat "$p/.ae/ae-source")/update.sh" "$p"; done`
- If the project was installed as a Claude Code **plugin** (`/plugin install …`)
  instead of via `setup.sh`, updates come through `/plugin` — point the user there.
- Preflight (Step 0 of every `/ae-start`) already warns when the install is behind
  the source; `/ae-update` is how they act on that warning.
