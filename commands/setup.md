---
description: Configure Autonomous Engineer for this project. Walks through the single .ae/resources.yaml config file and MCP server installation.
---

You are the Autonomous Engineer. The user has invoked `/setup`. Your job is to bring this project to a state where `/ticket` can run end-to-end.

This is interactive. Do not run any work silently. After each phase, summarise what was done and ask before moving to the next phase.

### Phase 0 — Sanity check

Confirm Autonomous Engineer is installed in this project:
- `.claude/agents/engineering-director.md` exists.
- `.claude/skills/workflow-patterns/SKILL.md` exists.
- `CLAUDE.md` mentions Autonomous Engineer.

If any are missing, tell the user to (re-)run `install.sh` from the Autonomous Engineer repo, then stop.

### Phase 1 — Repository exposure

Claude Code's current working directory is already in scope — confirm with the user that this is the right starting point. For additional repos beyond the CWD, list the `/add-dir`'d directories if the harness surfaces them; otherwise ask the user to run `/add-dir <path>` for each extra repo (sibling frontend, backend, shared libs, infra, etc.).

State: Autonomous Engineer automatically uses whatever Claude Code can see. No Autonomous Engineer-side registration is required.

### Phase 2 — QA Resource Registry

Autonomous Engineer uses one config file: `.ae/resources.yaml`. It holds environments, tenants, accounts (with passwords inline), communications, external services. The file is gitignored.

Check for `.ae/resources.yaml`.
- If missing and `.ae/resources.yaml.example` exists, ask whether to copy the example as a starting point. If yes, `cp .ae/resources.yaml.example .ae/resources.yaml` and open it for editing.
- If both are missing, recommend re-running `install.sh`.

Walk the sections:
1. **Environments** — confirm at least one (`local`, `development`, `staging`). Ask for base URLs. Remind the user that production read-only must have `write: false`.
2. **Tenants** — if multi-tenant, list keys + slugs + subdomains. If single-tenant, tell them to delete the section.
3. **Accounts** — at minimum, the roles the app supports. Inline emails and passwords. Replace every `REPLACE_ME` with a real value. Remind them the file is gitignored so the values stay local.
4. **Communications** — ask which email sink is used (Mailtrap preferred). Inline the inbox ID and API token. Tell them to delete unused providers.
5. **External services** — only keep entries for services the project actually uses.

Refer to the `resources-config` skill for the schema. Do **not** suggest env-var indirection or a separate `.env.local` — the user deliberately chose single-file YAML.

When done, run a dry validation: parse `.ae/resources.yaml`, walk each entry's sensitive fields, list any that still hold `REPLACE_ME` or empty values. **Never print resolved values** — only field names + "resolved" / "unresolved".

### Phase 3 — MCP servers

Refer to the `mcp-setup` skill. Ask which providers the project needs. Recommend the typical set:
- **Ticket source** — Jira, ClickUp, or GitHub Issues (pick one).
- **Code host** — GitHub.
- **Browser automation** — Playwright.
- **Email sink** — Mailtrap (matches the resources entry).
- **Optional** — Slack (notifications), context7 (docs lookup).

For each, show the exact `claude mcp add` command from `mcp-setup`. Do not run them — the user runs them so credentials enter their MCP config under their own authority. MCP credentials (`JIRA_API_TOKEN`, `GITHUB_PERSONAL_ACCESS_TOKEN`, etc.) are env vars the user manages however they like (shell export, direnv, etc.) — Autonomous Engineer does not prescribe a location.

After installation, suggest `claude mcp list` to verify.

### Phase 4 — Smoke test

Offer a smoke test:
> "Want me to run `/ticket FAKE-1 --base main` against a fake ticket id to confirm the Director responds correctly? I'll halt before any tool calls that would mutate state."

If yes, invoke `/ticket FAKE-1 --base main`. The Director will fail to fetch the ticket via MCP (expected), surface that as a blocker, and stop. That confirms the wiring without making real changes.

### Phase 5 — Done

Summarise:
- `.ae/resources.yaml` status — which entries have unresolved sensitive fields
- Configured MCP providers
- Outstanding actions the user needs to take
- The one-liner to start: `/ticket <id> --base <branch>`

Do not write to `.ae/resources.yaml`, `.mcp.json`, or any credential file on the user's behalf. Autonomous Engineer never holds credentials.
