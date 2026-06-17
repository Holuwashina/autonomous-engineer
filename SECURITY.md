# Security & permissions

Autonomous Engineer is designed so that **convenience never removes the controls that matter.** Turning off Claude Code's per-action permission *prompts* (so the operator isn't clicking "allow?" all day) is cosmetic — it does not disable any of the real safeguards below. This page is written so it can be shown to a client or security reviewer.

## What `--auto-approve` actually does

`setup.sh --auto-approve` writes a project-local `.claude/settings.local.json` that lets Claude Code run **the specific tools AE uses** (file read/write, shell, the Playwright/GitHub/ClickUp MCPs) without a per-action prompt. It is:

- **Scoped** — an explicit allow-list, not "allow everything." Anything outside the list still prompts.
- **Local & uncommitted** — it lives in `settings.local.json`, which is git-excluded. It is the operator's choice on their machine; it is never committed to the client's repository.
- **Backed by a deny-list** — catastrophic/exfiltration shell patterns are explicitly denied even though shell is allowed: `sudo`, `rm -rf /` and `rm -rf ~`, `chmod -R 777`, `curl … | sh`, `git push --force`, `dd if=`, `mkfs`, and similar.

It is **not** the same as `claude --dangerously-skip-permissions` (which approves *all* tools, including ones outside AE). For client work, use the scoped allow-list, not the blanket flag.

## The controls that stay on regardless

These are independent of the permission-prompt setting:

1. **Confirmation before any external write.** AE asks the operator before pushing a branch, opening/merging a PR (GitHub), or commenting on / transitioning a ticket (ClickUp/Jira). These are the only steps that gate on a human — and they always do.
2. **Enforced git safety hooks** (`hooks/`). Deterministic, not prompt-based: no direct commit/push to a protected branch (`main`/`master`/`dev`/`develop`/`production`/`release`), no non-fast-forward/force push, and the secrets file (`.ae/resources.yaml`) can never be committed.
3. **All work happens on a feature branch**, and **PRs are opened, never merged.** A human reviews and merges.
4. **Remote branch protection is the real backstop.** Local hooks catch the accidental mistake before it leaves the machine; the GitHub/GitLab branch-protection rules on `main` are what ultimately guarantee nothing lands without review. **Enable them** — they are not bypassable by any local setting.
5. **Secrets stay local.** `.ae/resources.yaml` holds credentials, is git-excluded, and the agents only ever report fields as "resolved/unresolved" — never the values.
6. **Production is read-only.** QA never runs mutating tests against a production environment; data setup happens on non-prod only.

## Recommended posture for client engagements

- Use `setup.sh --auto-approve` (scoped allow-list) — **not** `--dangerously-skip-permissions`.
- Enable **branch protection** on the client's default branch (required PR review, no force-push). This is the single most important control.
- Keep AE's external-write confirmations on (default).
- For a highly sensitive repo, simply **don't** run `--auto-approve` — leave the per-action prompts on. The pipeline works identically, just with more clicks.

In short: the agent operates autonomously on a branch, with deterministic guardrails on the dangerous operations and a mandatory human gate before anything reaches the client's GitHub or ticket system. Reducing prompt noise does not change that.
